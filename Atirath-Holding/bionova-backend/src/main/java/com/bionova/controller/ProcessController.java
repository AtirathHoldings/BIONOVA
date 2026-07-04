package com.bionova.controller;

import com.bionova.entity.ChecklistMaster;
import com.bionova.entity.ProcessMaster;
import com.bionova.entity.TaskLive;
import com.bionova.repository.ChecklistMasterRepository;
import com.bionova.repository.ProcessMasterRepository;
import com.bionova.repository.TaskLiveRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Process Controller — Manages the approval/rejection workflow for Live Tasks.
 *
 * ─── Task Status State Machine ─────────────────────────────────────────────
 *
 *   OPEN  ──────(employee starts)──────► WIP
 *   WIP   ──────(employee submits)──────► SUBMIT_REVIEW
 *   SUBMIT_REVIEW ─(CHECKER: YES)──────► UNDER_REVIEW
 *   SUBMIT_REVIEW ─(CHECKER: NO)───────► REWORK
 *   REWORK ─────(employee resubmits)───► SUBMIT_REVIEW
 *   UNDER_REVIEW ─(REVIEWER: YES)──────► COMPLETED
 *   UNDER_REVIEW ─(REVIEWER: NO)───────► REWORK
 *
 * ─── Endpoints ──────────────────────────────────────────────────────────────
 *
 *   POST  /api/process/task/{taskId}/start             → OPEN → WIP
 *   POST  /api/process/task/{taskId}/submit            → WIP  → SUBMIT_REVIEW
 *   POST  /api/process/task/{taskId}/resubmit          → REWORK → SUBMIT_REVIEW
 *   POST  /api/process/task/{taskId}/checker-action    → CHECKER YES/NO
 *   POST  /api/process/task/{taskId}/reviewer-action   → REVIEWER YES/NO
 *   GET   /api/process/task/{taskId}                   → full process history
 */
@RestController
@RequestMapping("/api/process")
public class ProcessController {

    @Autowired private ProcessMasterRepository processRepo;
    @Autowired private TaskLiveRepository      taskLiveRepo;
    @Autowired private ChecklistMasterRepository checklistRepo;

    // ── GET history ─────────────────────────────────────────────────────────

    /** Full audit log of all process actions for a task */
    @GetMapping("/task/{taskId}")
    public List<ProcessMaster> getHistory(@PathVariable Long taskId) {
        return processRepo.findByTaskIdOrderByOrdrIdAsc(taskId);
    }

    // ── START (OPEN → WIP) ─────────────────────────────────────────────────

    /**
     * Employee starts work on the task.
     * Body: { "empId": 1 }
     */
    @PostMapping("/task/{taskId}/start")
    @Transactional
    public ResponseEntity<?> startTask(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        TaskLive task = getTask(taskId);

        if (!"OPEN".equals(task.getTaskSts())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Task must be in OPEN status to start. Current: " + task.getTaskSts()));
        }

        task.setTaskSts("WIP");
        taskLiveRepo.save(task);

        ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "CHECKER", "YES");
        event.setRemarks("Task started — moved to WIP");
        processRepo.save(event);

        return ResponseEntity.ok(Map.of("taskSts", "WIP", "message", "Task started."));
    }

    // ── SUBMIT for Review (WIP → SUBMIT_REVIEW) ────────────────────────────

    /**
     * Employee submits task for checker review.
     * Body: { "empId": 1, "remarks": "Done" }
     *
     * Validates: if chkFlg=true, all checklist items must be completed first.
     */
    @PostMapping("/task/{taskId}/submit")
    @Transactional
    public ResponseEntity<?> submitTask(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        TaskLive task = getTask(taskId);

        if (!"WIP".equals(task.getTaskSts())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Task must be in WIP status to submit. Current: " + task.getTaskSts()));
        }

        // If checklist is enabled, all items must be done
        if (Boolean.TRUE.equals(task.getChkFlg())) {
            long pending = checklistRepo.countByTaskIdAndIsLiveAndChkStsAndSts(taskId, true, false, true);
            if (pending > 0) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message",
                                "Cannot submit: " + pending + " checklist item(s) still pending. Complete all checklist items first."));
            }
        }

        task.setTaskSts("SUBMIT_REVIEW");
        taskLiveRepo.save(task);

        ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "CHECKER", "YES");
        event.setRemarks(getString(body, "remarks", "Submitted for review"));
        processRepo.save(event);

        return ResponseEntity.ok(Map.of("taskSts", "SUBMIT_REVIEW", "message", "Task submitted for review."));
    }

    // ── RESUBMIT after REWORK (REWORK → SUBMIT_REVIEW) ────────────────────

    /**
     * Employee resubmits after rework.
     * Body: { "empId": 1, "remarks": "Fixed the issue" }
     */
    @PostMapping("/task/{taskId}/resubmit")
    @Transactional
    public ResponseEntity<?> resubmitTask(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        TaskLive task = getTask(taskId);

        if (!"REWORK".equals(task.getTaskSts())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Task must be in REWORK status to resubmit. Current: " + task.getTaskSts()));
        }

        // Re-validate checklist if enabled
        if (Boolean.TRUE.equals(task.getChkFlg())) {
            long pending = checklistRepo.countByTaskIdAndIsLiveAndChkStsAndSts(taskId, true, false, true);
            if (pending > 0) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message",
                                "Cannot resubmit: " + pending + " checklist item(s) still pending."));
            }
        }

        task.setTaskSts("SUBMIT_REVIEW");
        taskLiveRepo.save(task);

        ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "CHECKER", "YES");
        event.setRemarks(getString(body, "remarks", "Resubmitted after rework"));
        processRepo.save(event);

        return ResponseEntity.ok(Map.of("taskSts", "SUBMIT_REVIEW", "message", "Task resubmitted for review."));
    }

    // ── CHECKER ACTION (SUBMIT_REVIEW → UNDER_REVIEW | REWORK) ────────────

    /**
     * First-level checker approves or rejects.
     * Body:
     * {
     *   "empId": 2,
     *   "decision": "YES",          // "YES" → UNDER_REVIEW | "NO" → REWORK
     *   "remarks": "Looks good"
     * }
     */
    @PostMapping("/task/{taskId}/checker-action")
    @Transactional
    public ResponseEntity<?> checkerAction(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        TaskLive task = getTask(taskId);

        if (!"SUBMIT_REVIEW".equals(task.getTaskSts())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Task must be in SUBMIT_REVIEW status for checker action. Current: " + task.getTaskSts()));
        }

        String decision = getString(body, "decision", "").toUpperCase();
        if (!List.of("YES", "NO").contains(decision)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
        }

        String newStatus = "YES".equals(decision) ? "UNDER_REVIEW" : "REWORK";
        task.setTaskSts(newStatus);
        taskLiveRepo.save(task);

        ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "CHECKER", decision);
        event.setRemarks(getString(body, "remarks",
                "YES".equals(decision) ? "Checker approved — sent to reviewer" : "Checker rejected — rework required"));
        processRepo.save(event);

        String message = "YES".equals(decision)
                ? "Checker approved. Task moved to UNDER_REVIEW."
                : "Checker rejected. Task moved to REWORK.";

        return ResponseEntity.ok(Map.of("taskSts", newStatus, "message", message));
    }

    // ── REVIEWER ACTION (UNDER_REVIEW → COMPLETED | REWORK) ───────────────

    /**
     * Second-level reviewer approves or rejects.
     * Body:
     * {
     *   "rId": 1,                   // reviewer ID
     *   "decision": "YES",          // "YES" → COMPLETED | "NO" → REWORK
     *   "remarks": "Approved"
     * }
     */
    @PostMapping("/task/{taskId}/reviewer-action")
    @Transactional
    public ResponseEntity<?> reviewerAction(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        TaskLive task = getTask(taskId);

        if (!"UNDER_REVIEW".equals(task.getTaskSts())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Task must be in UNDER_REVIEW status for reviewer action. Current: " + task.getTaskSts()));
        }

        String decision = getString(body, "decision", "").toUpperCase();
        if (!List.of("YES", "NO").contains(decision)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
        }

        String newStatus = "YES".equals(decision) ? "COMPLETED" : "REWORK";
        task.setTaskSts(newStatus);

        // Record actual completion date when task is COMPLETED
        if ("COMPLETED".equals(newStatus)) {
            task.setActCmpDt(java.time.LocalDate.now());
        }
        taskLiveRepo.save(task);

        Integer rId = body.get("rId") != null
                ? Integer.valueOf(body.get("rId").toString()) : null;

        ProcessMaster event = new ProcessMaster();
        event.setTaskId(taskId);
        event.setOrdrId(nextOrder(taskId));
        event.setRId(rId);
        event.setActorRole("REVIEWER");
        event.setPrcsSts(decision);
        event.setRemarks(getString(body, "remarks",
                "YES".equals(decision) ? "Reviewer approved — COMPLETED" : "Reviewer rejected — rework required"));

        // Update running counts from history
        applyCountsFromHistory(taskId, event, decision);
        processRepo.save(event);

        String message = "YES".equals(decision)
                ? "Reviewer approved. Task COMPLETED! 🎉"
                : "Reviewer rejected. Task moved to REWORK.";

        return ResponseEntity.ok(Map.of("taskSts", newStatus, "message", message));
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private TaskLive getTask(Long taskId) {
        return taskLiveRepo.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found: " + taskId));
    }

    private int nextOrder(Long taskId) {
        List<ProcessMaster> history = processRepo.findByTaskIdOrderByOrdrIdAsc(taskId);
        return history.isEmpty() ? 1 : history.get(history.size() - 1).getOrdrId() + 1;
    }

    private ProcessMaster buildEvent(Long taskId, int order, Map<String, Object> body,
                                     String role, String decision) {
        ProcessMaster e = new ProcessMaster();
        e.setTaskId(taskId);
        e.setOrdrId(order);
        e.setActorRole(role);
        e.setPrcsSts(decision);

        if (body.get("empId") != null) {
            e.setEmpId(Long.valueOf(body.get("empId").toString()));
        }
        if (body.get("rId") != null) {
            e.setRId(Integer.valueOf(body.get("rId").toString()));
        }

        applyCountsFromHistory(taskId, e, decision);
        return e;
    }

    /** Sets yes_cnt and no_cnt cumulatively from past events */
    private void applyCountsFromHistory(Long taskId, ProcessMaster event, String decision) {
        List<ProcessMaster> history = processRepo.findByTaskIdOrderByOrdrIdAsc(taskId);
        int yesCnt = (int) history.stream().filter(h -> "YES".equals(h.getPrcsSts())).count();
        int noCnt  = (int) history.stream().filter(h -> "NO".equals(h.getPrcsSts())).count();
        if ("YES".equals(decision)) yesCnt++;
        else noCnt++;
        event.setYesCnt(yesCnt);
        event.setNoCnt(noCnt);
    }

    private String getString(Map<String, Object> map, String key, String defaultVal) {
        Object v = map.get(key);
        return v != null ? v.toString() : defaultVal;
    }
}
