package com.bionova.controller;

import com.bionova.entity.ChecklistMaster;
import com.bionova.entity.ProcessMaster;
import com.bionova.entity.TaskLive;
import com.bionova.entity.Assignment;
import com.bionova.entity.TaskStatusMaster;
import com.bionova.repository.ChecklistMasterRepository;
import com.bionova.repository.ProcessMasterRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.AssignmentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Process Controller — Manages the approval/rejection workflow for Live Tasks and Individual Tasks.
 */
@RestController
@RequestMapping("/api/process")
public class ProcessController {

    @Autowired private ProcessMasterRepository processRepo;
    @Autowired private TaskLiveRepository      taskLiveRepo;
    @Autowired private AssignmentRepository    assignmentRepo;
    @Autowired private ChecklistMasterRepository checklistRepo;
    @Autowired private com.bionova.repository.ReviewerMasterRepository reviewerMasterRepo;
    @Autowired private com.bionova.service.ProjectStatusCascadeService projectStatusCascadeService;

    // ── GET history ─────────────────────────────────────────────────────────

    /** Full audit log of all process actions for a task */
    @GetMapping("/task/{taskId}")
    public List<ProcessMaster> getHistory(@PathVariable Long taskId) {
        if (taskLiveRepo.existsById(taskId)) {
            return processRepo.findByTaskIdOrderByOrdrIdAsc(taskId);
        } else {
            return processRepo.findByEmpTaskIdOrderByOrdrIdAsc(taskId);
        }
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

        if (taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"OPEN".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in OPEN status to start. Current: " + currentStatus));
            }

            task.setTaskSts(TaskStatusMaster.WIP);
            taskLiveRepo.save(task);

            ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "REVIEWER", "YES");
            event.setRemarks("Task started — moved to WIP");
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", "WIP", "message", "Task started."));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"OPEN".equals(currentStatus) && !"DRAFT".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in OPEN or DRAFT status to start. Current: " + currentStatus));
            }

            task.setTaskSts(TaskStatusMaster.WIP);
            assignmentRepo.save(task);

            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "REVIEWER", "YES");
            event.setRemarks("Task started — moved to WIP");
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", "WIP", "message", "Task started."));
        }
    }

    // ── SUBMIT for Review (WIP → SUBMIT_REVIEW) ────────────────────────────

    /**
     * Employee submits task for checker review.
     * Body: { "empId": 1, "remarks": "Done" }
     */
    @PostMapping("/task/{taskId}/submit")
    @Transactional
    public ResponseEntity<?> submitTask(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        if (taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"WIP".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in WIP status to submit. Current: " + currentStatus));
            }

            if (Boolean.TRUE.equals(task.getChkFlg())) {
                long pending = checklistRepo.countByTaskIdAndIsLiveAndChkStsAndSts(taskId, true, false, true);
                if (pending > 0) {
                    return ResponseEntity.badRequest()
                            .body(Map.of("message",
                                    "Cannot submit: " + pending + " checklist item(s) still pending. Complete all checklist items first."));
                }
            }

            TaskStatusMaster targetStatus = Boolean.TRUE.equals(task.getPrcsFlg()) ? TaskStatusMaster.UNDER_REVIEW : TaskStatusMaster.COMPLETED;
            task.setTaskSts(targetStatus);
            if (TaskStatusMaster.COMPLETED.equals(targetStatus)) {
                task.setActCmpDt(java.time.LocalDate.now());
            }
            taskLiveRepo.save(task);

            ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "REVIEWER", "YES");
            event.setRemarks(getString(body, "remarks", TaskStatusMaster.COMPLETED.equals(targetStatus) ? "Task completed directly (no review process required)" : "Submitted for review"));
            processRepo.save(event);

            projectStatusCascadeService.cascadeStatusFromTask(taskId);

            return ResponseEntity.ok(Map.of("taskSts", targetStatus.getStatusNm(), "message", TaskStatusMaster.COMPLETED.equals(targetStatus) ? "Task completed successfully." : "Task submitted for review."));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"WIP".equals(currentStatus) && !"IN_PROGRESS".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in WIP or In Progress status to submit. Current: " + currentStatus));
            }

            if (Boolean.TRUE.equals(task.getChkFlg())) {
                long pending = checklistRepo.countByEmpTaskIdAndChkStsAndSts(taskId, false, true);
                if (pending > 0) {
                    return ResponseEntity.badRequest()
                            .body(Map.of("message",
                                    "Cannot submit: " + pending + " checklist item(s) still pending. Complete all checklist items first."));
                }
            }

            TaskStatusMaster targetStatus = Boolean.TRUE.equals(task.getPrcsFlg()) ? TaskStatusMaster.UNDER_REVIEW : TaskStatusMaster.COMPLETED;
            task.setTaskSts(targetStatus);
            assignmentRepo.save(task);

            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "REVIEWER", "YES");
            event.setRemarks(getString(body, "remarks", TaskStatusMaster.COMPLETED.equals(targetStatus) ? "Task completed directly (no review process required)" : "Submitted for review"));
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", targetStatus.getStatusNm(), "message", TaskStatusMaster.COMPLETED.equals(targetStatus) ? "Task completed successfully." : "Task submitted for review."));
        }
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

        if (taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"REWORK".equals(currentStatus) && !"REASSIGN".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in REWORK or REASSIGN status to resubmit. Current: " + currentStatus));
            }

            if (Boolean.TRUE.equals(task.getChkFlg())) {
                long pending = checklistRepo.countByTaskIdAndIsLiveAndChkStsAndSts(taskId, true, false, true);
                if (pending > 0) {
                    return ResponseEntity.badRequest()
                            .body(Map.of("message",
                                    "Cannot resubmit: " + pending + " checklist item(s) still pending."));
                }
            }

            task.setTaskSts(TaskStatusMaster.UNDER_REVIEW);
            taskLiveRepo.save(task);

            ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "REVIEWER", "YES");
            event.setRemarks(getString(body, "remarks", "Resubmitted after rework"));
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", "UNDER_REVIEW", "message", "Task resubmitted for review."));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"REWORK".equals(currentStatus) && !"REASSIGN".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in REWORK or REASSIGN status to resubmit. Current: " + currentStatus));
            }

            if (Boolean.TRUE.equals(task.getChkFlg())) {
                long pending = checklistRepo.countByEmpTaskIdAndChkStsAndSts(taskId, false, true);
                if (pending > 0) {
                    return ResponseEntity.badRequest()
                            .body(Map.of("message",
                                    "Cannot resubmit: " + pending + " checklist item(s) still pending."));
                }
            }

            task.setTaskSts(TaskStatusMaster.UNDER_REVIEW);
            assignmentRepo.save(task);

            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "REVIEWER", "YES");
            event.setRemarks(getString(body, "remarks", "Resubmitted after rework"));
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", "UNDER_REVIEW", "message", "Task resubmitted for review."));
        }
    }

    // ── REVIEWER ACTION (SUBMIT_REVIEW → UNDER_REVIEW | REWORK) ────────────

    /**
     * First-level reviewer approves or rejects.
     */
    @PostMapping("/task/{taskId}/checker-action")
    @Transactional
    public ResponseEntity<?> checkerAction(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        if (taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"UNDER_REVIEW".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in UNDER_REVIEW status for reviewer action. Current: " + currentStatus));
            }

            String decision = getString(body, "decision", "").toUpperCase();
            if (!List.of("YES", "NO").contains(decision)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
            }

            TaskStatusMaster newStatus = TaskStatusMaster.UNDER_REVIEW;
            if ("NO".equals(decision)) {
                String rejectionType = getString(body, "rejectionType", "REASSIGN").toUpperCase();
                if ("REWORK".equals(rejectionType)) {
                    newStatus = TaskStatusMaster.REWORK;
                } else {
                    newStatus = TaskStatusMaster.REASSIGN;
                }

                if (body.get("targetMId") != null) {
                    task.setMId(Long.valueOf(body.get("targetMId").toString()));
                }
                if (body.get("targetEmpId") != null) {
                    task.setEmpId(Long.valueOf(body.get("targetEmpId").toString()));
                }
            }
            task.setTaskSts(newStatus);
            taskLiveRepo.save(task);

            ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "REVIEWER", decision);
            event.setRemarks(getString(body, "remarks",
                    "YES".equals(decision) ? "Reviewer approved — sent to approver" : "Reviewer rejected — task sent back"));
            processRepo.save(event);

            if (TaskStatusMaster.REWORK.equals(newStatus) || TaskStatusMaster.REASSIGN.equals(newStatus)) {
                projectStatusCascadeService.cascadeReworkDownstream(taskId);
            }
            projectStatusCascadeService.cascadeStatusFromTask(taskId);

            String message = "YES".equals(decision)
                    ? "Reviewer approved. Task moved to UNDER_REVIEW."
                    : "Reviewer rejected. Task moved to " + newStatus.getStatusNm() + ".";

            return ResponseEntity.ok(Map.of("taskSts", newStatus.getStatusNm(), "message", message));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"UNDER_REVIEW".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in UNDER_REVIEW status for reviewer action. Current: " + currentStatus));
            }

            String decision = getString(body, "decision", "").toUpperCase();
            if (!List.of("YES", "NO").contains(decision)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
            }

            TaskStatusMaster newStatus = TaskStatusMaster.UNDER_REVIEW;
            if ("NO".equals(decision)) {
                String rejectionType = getString(body, "rejectionType", "REASSIGN").toUpperCase();
                if ("REWORK".equals(rejectionType)) {
                    newStatus = TaskStatusMaster.REWORK;
                } else {
                    newStatus = TaskStatusMaster.REASSIGN;
                }

                if (body.get("targetEmpId") != null) {
                    task.setEmpId(Long.valueOf(body.get("targetEmpId").toString()));
                }
            }
            task.setTaskSts(newStatus);
            assignmentRepo.save(task);

            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "REVIEWER", decision);
            event.setRemarks(getString(body, "remarks",
                    "YES".equals(decision) ? "Reviewer approved — sent to approver" : "Reviewer rejected — task sent back"));
            processRepo.save(event);

            String message = "YES".equals(decision)
                    ? "Reviewer approved. Task moved to UNDER_REVIEW."
                    : "Reviewer rejected. Task moved to " + newStatus.getStatusNm() + ".";

            return ResponseEntity.ok(Map.of("taskSts", newStatus.getStatusNm(), "message", message));
        }
    }

    // ── APPROVER ACTION (UNDER_REVIEW → COMPLETED | REWORK) ───────────────

    /**
     * Second-level approver approves or rejects.
     */
    @PostMapping("/task/{taskId}/reviewer-action")
    @Transactional
    public ResponseEntity<?> reviewerAction(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        if (taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"UNDER_REVIEW".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in UNDER_REVIEW status for approver action. Current: " + currentStatus));
            }

            String decision = getString(body, "decision", "").toUpperCase();
            if (!List.of("YES", "NO").contains(decision)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
            }

            TaskStatusMaster newStatus = TaskStatusMaster.COMPLETED;
            if ("NO".equals(decision)) {
                String rejectionType = getString(body, "rejectionType", "REASSIGN").toUpperCase();
                if ("REWORK".equals(rejectionType)) {
                    newStatus = TaskStatusMaster.REWORK;
                } else {
                    newStatus = TaskStatusMaster.REASSIGN;
                }

                if (body.get("targetMId") != null) {
                    task.setMId(Long.valueOf(body.get("targetMId").toString()));
                }
                if (body.get("targetEmpId") != null) {
                    task.setEmpId(Long.valueOf(body.get("targetEmpId").toString()));
                }
            }
            task.setTaskSts(newStatus);

            if (TaskStatusMaster.COMPLETED.equals(newStatus)) {
                task.setActCmpDt(java.time.LocalDate.now());
            }
            taskLiveRepo.save(task);

            Integer rId = body.get("rId") != null
                    ? Integer.valueOf(body.get("rId").toString()) : null;
            if (rId == null) {
                rId = getRoleIdForRole("APPROVER");
            }
            Long empId = body.get("empId") != null
                    ? Long.valueOf(body.get("empId").toString()) : null;

            ProcessMaster event = new ProcessMaster();
            event.setTaskId(taskId);
            event.setOrdrId(nextOrder(taskId));
            event.setEmpId(empId);
            event.setRId(rId);
            event.setPrcsSts(decision);
            event.setRemarks(getString(body, "remarks",
                    "YES".equals(decision) ? "Approver approved — COMPLETED" : "Approver rejected — task sent back"));

            applyCountsFromHistory(taskId, event, decision);
            processRepo.save(event);

            if (TaskStatusMaster.REWORK.equals(newStatus) || TaskStatusMaster.REASSIGN.equals(newStatus)) {
                projectStatusCascadeService.cascadeReworkDownstream(taskId);
            }
            projectStatusCascadeService.cascadeStatusFromTask(taskId);

            String message = "YES".equals(decision)
                    ? "Approver approved. Task COMPLETED! 🎉"
                    : "Approver rejected. Task moved to " + newStatus.getStatusNm() + ".";

            return ResponseEntity.ok(Map.of("taskSts", newStatus.getStatusNm(), "message", message));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"UNDER_REVIEW".equals(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in UNDER_REVIEW status for approver action. Current: " + currentStatus));
            }

            String decision = getString(body, "decision", "").toUpperCase();
            if (!List.of("YES", "NO").contains(decision)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
            }

            TaskStatusMaster newStatus = TaskStatusMaster.COMPLETED;
            if ("NO".equals(decision)) {
                String rejectionType = getString(body, "rejectionType", "REASSIGN").toUpperCase();
                if ("REWORK".equals(rejectionType)) {
                    newStatus = TaskStatusMaster.REWORK;
                } else {
                    newStatus = TaskStatusMaster.REASSIGN;
                }

                if (body.get("targetEmpId") != null) {
                    task.setEmpId(Long.valueOf(body.get("targetEmpId").toString()));
                }
            }
            task.setTaskSts(newStatus);
            assignmentRepo.save(task);

            Integer rId = body.get("rId") != null
                    ? Integer.valueOf(body.get("rId").toString()) : null;
            if (rId == null) {
                rId = getRoleIdForRole("APPROVER");
            }
            Long empId = body.get("empId") != null
                    ? Long.valueOf(body.get("empId").toString()) : null;

            ProcessMaster event = new ProcessMaster();
            event.setEmpTaskId(taskId);
            event.setOrdrId(nextOrderForIndividual(taskId));
            event.setEmpId(empId);
            event.setRId(rId);
            event.setPrcsSts(decision);
            event.setRemarks(getString(body, "remarks",
                    "YES".equals(decision) ? "Approver approved — COMPLETED" : "Approver rejected — task sent back"));

            applyCountsFromHistoryForIndividual(taskId, event, decision);
            processRepo.save(event);

            String message = "YES".equals(decision)
                    ? "Approver approved. Task COMPLETED! 🎉"
                    : "Approver rejected. Task moved to " + newStatus.getStatusNm() + ".";

            return ResponseEntity.ok(Map.of("taskSts", newStatus.getStatusNm(), "message", message));
        }
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private Integer getRoleIdForRole(String role) {
        String roleName = "REVIEWER".equalsIgnoreCase(role) ? "Reviewer" : "Approver";
        return reviewerMasterRepo.findAll().stream()
                .filter(r -> roleName.equalsIgnoreCase(r.getRNm()))
                .findFirst()
                .map(com.bionova.entity.ReviewerMaster::getRId)
                .orElseGet(() -> {
                    com.bionova.entity.ReviewerMaster rm = new com.bionova.entity.ReviewerMaster();
                    rm.setRNm(roleName);
                    rm = reviewerMasterRepo.save(rm);
                    return rm.getRId();
                });
    }

    private TaskLive getTask(Long taskId) {
        return taskLiveRepo.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found: " + taskId));
    }

    private int nextOrder(Long taskId) {
        List<ProcessMaster> history = processRepo.findByTaskIdOrderByOrdrIdAsc(taskId);
        return history.isEmpty() ? 1 : history.get(history.size() - 1).getOrdrId() + 1;
    }

    private int nextOrderForIndividual(Long empTaskId) {
        List<ProcessMaster> history = processRepo.findByEmpTaskIdOrderByOrdrIdAsc(empTaskId);
        return history.isEmpty() ? 1 : history.get(history.size() - 1).getOrdrId() + 1;
    }

    private ProcessMaster buildEvent(Long taskId, int order, Map<String, Object> body,
                                     String role, String decision) {
        ProcessMaster e = new ProcessMaster();
        e.setTaskId(taskId);
        e.setOrdrId(order);
        e.setPrcsSts(decision);

        if (body.get("empId") != null) {
            e.setEmpId(Long.valueOf(body.get("empId").toString()));
        }
        if (body.get("rId") != null) {
            e.setRId(Integer.valueOf(body.get("rId").toString()));
        }
        if (e.getRId() == null) {
            e.setRId(getRoleIdForRole(role));
        }

        applyCountsFromHistory(taskId, e, decision);
        return e;
    }

    private ProcessMaster buildIndividualEvent(Long empTaskId, int order, Map<String, Object> body,
                                             String role, String decision) {
        ProcessMaster e = new ProcessMaster();
        e.setEmpTaskId(empTaskId);
        e.setOrdrId(order);
        e.setPrcsSts(decision);

        if (body.get("empId") != null) {
            e.setEmpId(Long.valueOf(body.get("empId").toString()));
        }
        if (body.get("rId") != null) {
            e.setRId(Integer.valueOf(body.get("rId").toString()));
        }
        if (e.getRId() == null) {
            e.setRId(getRoleIdForRole(role));
        }

        applyCountsFromHistoryForIndividual(empTaskId, e, decision);
        return e;
    }

    private void applyCountsFromHistory(Long taskId, ProcessMaster event, String decision) {
        List<ProcessMaster> history = processRepo.findByTaskIdOrderByOrdrIdAsc(taskId);
        int yesCnt = (int) history.stream().filter(h -> "YES".equals(h.getPrcsSts())).count();
        int noCnt  = (int) history.stream().filter(h -> "NO".equals(h.getPrcsSts())).count();
        if ("YES".equals(decision)) yesCnt++;
        else noCnt++;
        event.setYesCnt(yesCnt);
        event.setNoCnt(noCnt);
    }

    private void applyCountsFromHistoryForIndividual(Long empTaskId, ProcessMaster event, String decision) {
        List<ProcessMaster> history = processRepo.findByEmpTaskIdOrderByOrdrIdAsc(empTaskId);
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
