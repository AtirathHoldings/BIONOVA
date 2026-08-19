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
    @Autowired private com.bionova.repository.MilestoneLiveRepository milestoneLiveRepo;
    @Autowired private com.bionova.repository.ReviewerMasterRepository reviewerMasterRepo;
    @Autowired private com.bionova.service.ProjectStatusCascadeService projectStatusCascadeService;

    private String getPrerequisitesErrorMessage(TaskLive task) {
        if (task == null) return null;
        if (Boolean.TRUE.equals(task.getTaskDepFlg()) && "SEQUENTIAL".equalsIgnoreCase(task.getTaskDepTyp()) && task.getDepTaskId() != null) {
            TaskLive pred = taskLiveRepo.findById(task.getDepTaskId()).orElse(null);
            if (pred != null) {
                String pSts = pred.getTaskSts() != null ? pred.getTaskSts().getStatusNm() : "";
                if (!"Closed".equalsIgnoreCase(pSts) && !"Completed".equalsIgnoreCase(pSts)) {
                    String code = pred.getTaskCd() != null ? pred.getTaskCd() : "Predecessor";
                    String name = pred.getTaskNm() != null ? pred.getTaskNm() : "";
                    return "Cannot proceed: Sequential predecessor task [" + code + " - " + name + "] must be completed and closed first.";
                }
            }
        }
        if (task.getMId() != null) {
            com.bionova.entity.MilestoneLive ms = milestoneLiveRepo.findById(task.getMId()).orElse(null);
            if (ms != null && Boolean.TRUE.equals(ms.getMlstnDepFlg()) && "SEQUENTIAL".equalsIgnoreCase(ms.getMlstnDepTyp()) && ms.getMlstnDepMId() != null) {
                com.bionova.entity.MilestoneLive predMs = milestoneLiveRepo.findById(ms.getMlstnDepMId()).orElse(null);
                if (predMs != null && !"CLOSED".equalsIgnoreCase(predMs.getMlstnSts())) {
                    String msCd = predMs.getMlstnCd() != null ? predMs.getMlstnCd() : "Predecessor";
                    String msTtl = predMs.getMlstnTtl() != null ? predMs.getMlstnTtl() : "";
                    return "Cannot proceed: Sequential predecessor milestone [" + msCd + " - " + msTtl + "] must be closed first.";
                }
            }
        }
        return null;
    }

    // ── GET history ─────────────────────────────────────────────────────────

    /** Full audit log of all process actions for a task */
    @GetMapping("/task/{taskId}")
    public List<ProcessMaster> getHistory(
            @PathVariable Long taskId,
            @RequestParam(required = false, defaultValue = "false") boolean isIndividual) {
        if (!isIndividual) {
            return processRepo.findByTaskIdOrderByOrdrIdAsc(taskId);
        } else {
            return processRepo.findByEmpTaskIdOrderByOrdrIdAsc(taskId);
        }
    }

    /**
     * Employee starts work on the task.
     * Body: { "empId": 1 }
     */
    @PostMapping("/task/{taskId}/start")
    @Transactional
    public ResponseEntity<?> startTask(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {

        boolean isIndividual = Boolean.parseBoolean(String.valueOf(body.getOrDefault("isIndividual", "false")));
        if (!isIndividual && taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String prereqErr = getPrerequisitesErrorMessage(task);
            if (prereqErr != null) {
                return ResponseEntity.badRequest().body(Map.of("message", prereqErr));
            }

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"OPEN".equalsIgnoreCase(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in OPEN status to start. Current: " + currentStatus));
            }

            task.setTaskSts(TaskStatusMaster.WIP);
            task.setSubStatus(null);
            task.setPrcsYesActn("NONE");
            taskLiveRepo.save(task);

            ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "EXECUTOR", "YES");
            event.setRemarks("Task started — moved to WIP");
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", "WIP", "message", "Task started."));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"OPEN".equalsIgnoreCase(currentStatus) && !"DRAFT".equalsIgnoreCase(currentStatus)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in OPEN or DRAFT status to start. Current: " + currentStatus));
            }

            task.setTaskSts(TaskStatusMaster.WIP);
            task.setSubStatus(null);
            task.setPrcsYesActn("NONE");
            assignmentRepo.save(task);

            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "EXECUTOR", "YES");
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

        boolean isIndividual = Boolean.parseBoolean(String.valueOf(body.getOrDefault("isIndividual", "false")));
        if (!isIndividual && taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String prereqErr = getPrerequisitesErrorMessage(task);
            if (prereqErr != null) {
                return ResponseEntity.badRequest().body(Map.of("message", prereqErr));
            }

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"WIP".equalsIgnoreCase(currentStatus)) {
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

            boolean needsReview = Boolean.TRUE.equals(task.getPrcsFlg());
            TaskStatusMaster targetStatus = needsReview ? TaskStatusMaster.WIP : TaskStatusMaster.CLOSED;
            String newSubStatus = needsReview ? "Under Review" : getCompletionSubStatus(task.getEndDt());

            task.setTaskSts(targetStatus);
            task.setSubStatus(newSubStatus);
            if (!needsReview) {
                task.setActCmpDt(java.time.LocalDate.now());
                task.setPrcsYesActn("NONE");
            } else {
                task.setPrcsYesActn(getString(body, "prcsYesActn", "PENDING_REVIEWER"));
            }
            taskLiveRepo.save(task);

            ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "EXECUTOR", "YES");
            event.setRemarks(getString(body, "remarks", ""));
            processRepo.save(event);

            projectStatusCascadeService.cascadeStatusFromTask(taskId);

            return ResponseEntity.ok(Map.of("taskSts", targetStatus.getStatusNm(), "subStatus", newSubStatus != null ? newSubStatus : "", "message", !needsReview ? "Task completed successfully." : "Task submitted for review."));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            if (!"WIP".equalsIgnoreCase(currentStatus) && !"IN_PROGRESS".equalsIgnoreCase(currentStatus)) {
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

            boolean needsReview = Boolean.TRUE.equals(task.getPrcsFlg());
            TaskStatusMaster targetStatus = needsReview ? TaskStatusMaster.WIP : TaskStatusMaster.CLOSED;
            String newSubStatus = needsReview ? "Under Review" : getCompletionSubStatus(task.getEndDt());

            task.setTaskSts(targetStatus);
            task.setSubStatus(newSubStatus);
            if (!needsReview) {
                task.setPrcsYesActn("NONE");
            } else {
                task.setPrcsYesActn(getString(body, "prcsYesActn", "PENDING_REVIEWER"));
            }
            assignmentRepo.save(task);

            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "EXECUTOR", "YES");
            event.setRemarks(getString(body, "remarks", ""));
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", targetStatus.getStatusNm(), "subStatus", newSubStatus != null ? newSubStatus : "", "message", !needsReview ? "Task completed successfully." : "Task submitted for review."));
        }
    }

    // ── UPDATE PROGRESS (Intermediate Saves) ──────────────────────────────
    @PostMapping("/task/{taskId}/update-progress")
    @Transactional
    public ResponseEntity<?> updateProgress(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {
        
        boolean isIndividual = Boolean.parseBoolean(String.valueOf(body.getOrDefault("isIndividual", "false")));
        if (!isIndividual && taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);
            
            ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "EXECUTOR", "UPD");
            event.setRemarks(getString(body, "remarks", "Progress updated"));
            processRepo.save(event);
            
            return ResponseEntity.ok(Map.of("message", "Progress logged."));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));
            
            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "EXECUTOR", "UPD");
            event.setRemarks(getString(body, "remarks", "Progress updated"));
            processRepo.save(event);
            
            return ResponseEntity.ok(Map.of("message", "Progress logged."));
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

        boolean isIndividual = Boolean.parseBoolean(String.valueOf(body.getOrDefault("isIndividual", "false")));
        if (!isIndividual && taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            String subStatus = task.getSubStatus() != null ? task.getSubStatus() : "";
            boolean isProcessReworkOrReassign = "REWORK".equalsIgnoreCase(task.getPrcsYesActn()) || "REASSIGN".equalsIgnoreCase(task.getPrcsYesActn());
            if (!"WIP".equalsIgnoreCase(currentStatus) || (!"Rework".equalsIgnoreCase(subStatus) && !"Reassign".equalsIgnoreCase(subStatus) && !isProcessReworkOrReassign)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in WIP status with Rework or Reassign sub-status to resubmit. Current: " + currentStatus + " (" + subStatus + ")"));
            }

            if (Boolean.TRUE.equals(task.getChkFlg())) {
                long pending = checklistRepo.countByTaskIdAndIsLiveAndChkStsAndSts(taskId, true, false, true);
                if (pending > 0) {
                    return ResponseEntity.badRequest()
                            .body(Map.of("message",
                                    "Cannot resubmit: " + pending + " checklist item(s) still pending."));
                }
            }

            task.setTaskSts(TaskStatusMaster.WIP);
            task.setSubStatus("Under Review");
            task.setPrcsYesActn(getString(body, "prcsYesActn", "PENDING_REVIEWER"));
            taskLiveRepo.save(task);

            ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "EXECUTOR", "YES");
            event.setRemarks(getString(body, "remarks", ""));
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", "WIP", "subStatus", "Under Review", "message", "Task resubmitted for review."));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            String subStatus = task.getSubStatus() != null ? task.getSubStatus() : "";
            boolean isProcessReworkOrReassign = "REWORK".equalsIgnoreCase(task.getPrcsYesActn()) || "REASSIGN".equalsIgnoreCase(task.getPrcsYesActn());
            if (!"WIP".equalsIgnoreCase(currentStatus) || (!"Rework".equalsIgnoreCase(subStatus) && !"Reassign".equalsIgnoreCase(subStatus) && !isProcessReworkOrReassign)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in WIP status with Rework or Reassign sub-status to resubmit. Current: " + currentStatus + " (" + subStatus + ")"));
            }

            if (Boolean.TRUE.equals(task.getChkFlg())) {
                long pending = checklistRepo.countByEmpTaskIdAndChkStsAndSts(taskId, false, true);
                if (pending > 0) {
                    return ResponseEntity.badRequest()
                            .body(Map.of("message",
                                    "Cannot resubmit: " + pending + " checklist item(s) still pending."));
                }
            }

            task.setTaskSts(TaskStatusMaster.WIP);
            task.setSubStatus("Under Review");
            task.setPrcsYesActn(getString(body, "prcsYesActn", "PENDING_REVIEWER"));
            assignmentRepo.save(task);

            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "EXECUTOR", "YES");
            event.setRemarks(getString(body, "remarks", ""));
            processRepo.save(event);

            return ResponseEntity.ok(Map.of("taskSts", "WIP", "subStatus", "Under Review", "message", "Task resubmitted for review."));
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

        boolean isIndividual = Boolean.parseBoolean(String.valueOf(body.getOrDefault("isIndividual", "false")));
        if (!isIndividual && taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            String subStatus = task.getSubStatus() != null ? task.getSubStatus() : "";
            if (!"WIP".equalsIgnoreCase(currentStatus) || (!"Under Review".equalsIgnoreCase(subStatus) && !"PENDING_REVIEWER".equalsIgnoreCase(task.getPrcsYesActn()))) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in WIP status with Under Review sub-status for reviewer action. Current: " + currentStatus + " (" + subStatus + "), PrcsYesActn: " + task.getPrcsYesActn()));
            }

            String decision = getString(body, "decision", "").toUpperCase();
            if (!List.of("YES", "NO").contains(decision)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
            }

            String targetSubStatus = "Under Review";
            if ("NO".equals(decision)) {
                String rejectionType = getString(body, "rejectionType", "REASSIGN").toUpperCase();
                targetSubStatus = "REWORK".equals(rejectionType) ? "Rework" : "Reassign";

                if ("REASSIGN".equals(rejectionType)) {
                    if (body.get("targetEmpId") != null) {
                        try {
                            task.setEmpId(Long.valueOf(body.get("targetEmpId").toString()));
                        } catch (Exception ignored) {}
                    }
                }
            }

            task.setTaskSts(TaskStatusMaster.WIP);
            task.setSubStatus(targetSubStatus);
            if ("NO".equals(decision)) {
                task.setPrcsYesActn(getString(body, "rejectionType", "REASSIGN").toUpperCase());
            } else {
                task.setPrcsYesActn("PENDING_APPROVER");
            }
            String eventRemarks = getString(body, "remarks", "");

            TaskLive targetTask = null;
            if ("NO".equals(decision) && "Rework".equals(targetSubStatus)) {
                Long targetMId = null;
                if (body.get("targetMId") != null && !body.get("targetMId").toString().isBlank()) {
                    try { targetMId = Long.valueOf(body.get("targetMId").toString()); } catch (Exception ignored) {}
                }
                Long targetTaskId = null;
                if (body.get("targetTaskId") != null && !body.get("targetTaskId").toString().isBlank()) {
                    try { targetTaskId = Long.valueOf(body.get("targetTaskId").toString()); } catch (Exception ignored) {}
                }
                targetTask = projectStatusCascadeService.routeReworkToPreviousMilestoneTask(taskId, targetMId, targetTaskId);
            }

            boolean isCrossTaskRework = (targetTask != null && !targetTask.getTaskId().equals(taskId));

            if (!isCrossTaskRework) {
                if ("NO".equals(decision)) {
                    String prefix = "Rework".equals(targetSubStatus) ? "[Rejected - Reviewer]" : "[Reassigned - Reviewer]";
                    String existingRem = task.getAddlRem();
                    String newRem = prefix + ": " + eventRemarks;
                    if (existingRem != null && !existingRem.trim().isEmpty()) {
                        newRem = existingRem + "\n---\n" + newRem;
                    }
                    task.setAddlRem(newRem);
                }
                taskLiveRepo.save(task);

                ProcessMaster event = buildEvent(taskId, nextOrder(taskId), body, "REVIEWER", decision);
                event.setRemarks(eventRemarks);
                processRepo.save(event);
            } else {
                // For cross-task rework, only targetTask gets the remarks and ProcessMaster event
                String prefix = "[Rejected - Reviewer]";
                String existingRem = targetTask.getAddlRem();
                String newRem = prefix + ": " + eventRemarks;
                if (existingRem != null && !existingRem.trim().isEmpty()) {
                    newRem = existingRem + "\n---\n" + newRem;
                }
                targetTask.setAddlRem(newRem);
                taskLiveRepo.save(targetTask);

                ProcessMaster targetEvent = buildEvent(targetTask.getTaskId(), nextOrder(targetTask.getTaskId()), body, "REVIEWER", decision);
                targetEvent.setRemarks(eventRemarks);
                processRepo.save(targetEvent);
            }

            if ("NO".equals(decision)) {
                // Reopen all checklists for this task so executor must do them again
                List<ChecklistMaster> checklists = checklistRepo.findByTaskIdAndIsLive(taskId, true);
                if (checklists != null && !checklists.isEmpty()) {
                    for (ChecklistMaster item : checklists) {
                        item.setChkSts(false);
                        item.setCompletedTs(null);
                    }
                    checklistRepo.saveAll(checklists);
                }
            }

            if ("NO".equals(decision) && ("Rework".equals(targetSubStatus) || "Reassign".equals(targetSubStatus))) {
                projectStatusCascadeService.cascadeReworkDownstream(taskId);
            }
            projectStatusCascadeService.cascadeStatusFromTask(taskId);

            String message = "YES".equals(decision)
                    ? "Reviewer approved. Task moved to Under Review."
                    : "Reviewer rejected. Task moved to WIP (" + targetSubStatus + ").";

            return ResponseEntity.ok(Map.of("taskSts", "WIP", "subStatus", targetSubStatus, "message", message));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            String subStatus = task.getSubStatus() != null ? task.getSubStatus() : "";
            if (!"WIP".equalsIgnoreCase(currentStatus) || (!"Under Review".equalsIgnoreCase(subStatus) && !"PENDING_REVIEWER".equalsIgnoreCase(task.getPrcsYesActn()))) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in WIP status with Under Review sub-status for reviewer action. Current: " + currentStatus + " (" + subStatus + "), PrcsYesActn: " + task.getPrcsYesActn()));
            }

            String decision = getString(body, "decision", "").toUpperCase();
            if (!List.of("YES", "NO").contains(decision)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
            }

            String targetSubStatus = "Under Review";
            if ("NO".equals(decision)) {
                String rejectionType = getString(body, "rejectionType", "REASSIGN").toUpperCase();
                targetSubStatus = "REWORK".equals(rejectionType) ? "Rework" : "Reassign";

                if (body.get("targetEmpId") != null) {
                    task.setEmpId(Long.valueOf(body.get("targetEmpId").toString()));
                }
            }

            task.setTaskSts(TaskStatusMaster.WIP);
            task.setSubStatus(targetSubStatus);
            if ("NO".equals(decision)) {
                task.setPrcsYesActn(getString(body, "rejectionType", "REASSIGN").toUpperCase());
            } else {
                task.setPrcsYesActn("PENDING_APPROVER");
            }
            String eventRemarks = getString(body, "remarks", "");
            if ("NO".equals(decision)) {
                String prefix = "Rework".equals(targetSubStatus) ? "[Rejected - Reviewer]" : "[Reassigned - Reviewer]";
                String existingRem = task.getRemarks();
                String newRem = prefix + ": " + eventRemarks;
                if (existingRem != null && !existingRem.trim().isEmpty()) {
                    newRem = existingRem + "\n---\n" + newRem;
                }
                task.setRemarks(newRem);
            }
            assignmentRepo.save(task);

            ProcessMaster event = buildIndividualEvent(taskId, nextOrderForIndividual(taskId), body, "REVIEWER", decision);
            event.setRemarks(eventRemarks);
            processRepo.save(event);

            if ("NO".equals(decision)) {
                List<ChecklistMaster> checklists = checklistRepo.findByTaskIdAndIsLive(taskId, false);
                if (checklists != null && !checklists.isEmpty()) {
                    for (ChecklistMaster item : checklists) {
                        item.setChkSts(false);
                        item.setCompletedTs(null);
                    }
                    checklistRepo.saveAll(checklists);
                }
            }

            String message = "YES".equals(decision)
                    ? "Reviewer approved. Task moved to Under Review."
                    : "Reviewer rejected. Task moved to WIP (" + targetSubStatus + ").";

            return ResponseEntity.ok(Map.of("taskSts", "WIP", "subStatus", targetSubStatus, "message", message));
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

        boolean isIndividual = Boolean.parseBoolean(String.valueOf(body.getOrDefault("isIndividual", "false")));
        if (!isIndividual && taskLiveRepo.existsById(taskId)) {
            TaskLive task = getTask(taskId);

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            String subStatus = task.getSubStatus() != null ? task.getSubStatus() : "";
            if (!"WIP".equalsIgnoreCase(currentStatus) || (!"Under Review".equalsIgnoreCase(subStatus) && !"PENDING_APPROVER".equalsIgnoreCase(task.getPrcsYesActn()))) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in WIP status with Under Review sub-status for approver action. Current: " + currentStatus + " (" + subStatus + "), PrcsYesActn: " + task.getPrcsYesActn()));
            }

            String decision = getString(body, "decision", "").toUpperCase();
            if (!List.of("YES", "NO").contains(decision)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
            }

            TaskStatusMaster targetStatus = TaskStatusMaster.CLOSED;
            String targetSubStatus = getCompletionSubStatus(task.getEndDt());

            if ("NO".equals(decision)) {
                targetStatus = TaskStatusMaster.WIP;
                String rejectionType = getString(body, "rejectionType", "REASSIGN").toUpperCase();
                targetSubStatus = "REWORK".equals(rejectionType) ? "Rework" : "Reassign";

                if ("REASSIGN".equals(rejectionType)) {
                    if (body.get("targetEmpId") != null) {
                        try {
                            task.setEmpId(Long.valueOf(body.get("targetEmpId").toString()));
                        } catch (Exception ignored) {}
                    }
                }
            }

            task.setTaskSts(targetStatus);
            task.setSubStatus(targetSubStatus);
            if ("NO".equals(decision)) {
                task.setPrcsYesActn(getString(body, "rejectionType", "REASSIGN").toUpperCase());
            } else {
                task.setPrcsYesActn("NONE");
            }

            if (TaskStatusMaster.CLOSED.equals(targetStatus)) {
                task.setActCmpDt(java.time.LocalDate.now());
            }
            
            String eventRemarks = getString(body, "remarks", "");

            TaskLive targetTask = null;
            if ("NO".equals(decision) && "Rework".equals(targetSubStatus)) {
                Long targetMId = null;
                if (body.get("targetMId") != null && !body.get("targetMId").toString().isBlank()) {
                    try { targetMId = Long.valueOf(body.get("targetMId").toString()); } catch (Exception ignored) {}
                }
                Long targetTaskId = null;
                if (body.get("targetTaskId") != null && !body.get("targetTaskId").toString().isBlank()) {
                    try { targetTaskId = Long.valueOf(body.get("targetTaskId").toString()); } catch (Exception ignored) {}
                }
                targetTask = projectStatusCascadeService.routeReworkToPreviousMilestoneTask(taskId, targetMId, targetTaskId);
            }

            boolean isCrossTaskRework = (targetTask != null && !targetTask.getTaskId().equals(taskId));

            if (!isCrossTaskRework) {
                if ("NO".equals(decision)) {
                    String prefix = "Rework".equals(targetSubStatus) ? "[Rejected - Approver]" : "[Reassigned - Approver]";
                    String existingRem = task.getAddlRem();
                    String newRem = prefix + ": " + eventRemarks;
                    if (existingRem != null && !existingRem.trim().isEmpty()) {
                        newRem = existingRem + "\n---\n" + newRem;
                    }
                    task.setAddlRem(newRem);
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
                event.setRemarks(eventRemarks);

                applyCountsFromHistory(taskId, event, decision);
                processRepo.save(event);
            } else {
                // For cross-task rework, only targetTask gets the remarks and ProcessMaster event
                String prefix = "[Rejected - Approver]";
                String existingRem = targetTask.getAddlRem();
                String newRem = prefix + ": " + eventRemarks;
                if (existingRem != null && !existingRem.trim().isEmpty()) {
                    newRem = existingRem + "\n---\n" + newRem;
                }
                targetTask.setAddlRem(newRem);
                taskLiveRepo.save(targetTask);

                Integer targetRId = body.get("rId") != null
                        ? Integer.valueOf(body.get("rId").toString()) : null;
                if (targetRId == null) {
                    targetRId = getRoleIdForRole("APPROVER");
                }
                Long targetEmpId = body.get("empId") != null
                        ? Long.valueOf(body.get("empId").toString()) : null;

                ProcessMaster targetEvent = new ProcessMaster();
                targetEvent.setTaskId(targetTask.getTaskId());
                targetEvent.setOrdrId(nextOrder(targetTask.getTaskId()));
                targetEvent.setEmpId(targetEmpId);
                targetEvent.setRId(targetRId);
                targetEvent.setPrcsSts(decision);
                targetEvent.setRemarks(eventRemarks);
                applyCountsFromHistory(targetTask.getTaskId(), targetEvent, decision);
                processRepo.save(targetEvent);
            }

            if ("NO".equals(decision)) {
                // Reopen all checklists for this task so executor must do them again
                List<ChecklistMaster> checklists = checklistRepo.findByTaskIdAndIsLive(taskId, true);
                if (checklists != null && !checklists.isEmpty()) {
                    for (ChecklistMaster item : checklists) {
                        item.setChkSts(false);
                        item.setCompletedTs(null);
                    }
                    checklistRepo.saveAll(checklists);
                }
            }

            if (TaskStatusMaster.WIP.equals(targetStatus) && ("Rework".equals(targetSubStatus) || "Reassign".equals(targetSubStatus))) {
                projectStatusCascadeService.cascadeReworkDownstream(taskId);
            }
            projectStatusCascadeService.cascadeStatusFromTask(taskId);

            String message = "YES".equals(decision)
                    ? "Approver approved. Task CLOSED! 🎉"
                    : "Approver rejected. Task moved to WIP (" + targetSubStatus + ").";

            return ResponseEntity.ok(Map.of("taskSts", targetStatus.getStatusNm(), "subStatus", targetSubStatus, "message", message));
        } else {
            Assignment task = assignmentRepo.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found with ID: " + taskId));

            String currentStatus = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
            String subStatus = task.getSubStatus() != null ? task.getSubStatus() : "";
            if (!"WIP".equalsIgnoreCase(currentStatus) || (!"Under Review".equalsIgnoreCase(subStatus) && !"PENDING_APPROVER".equalsIgnoreCase(task.getPrcsYesActn()))) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Task must be in WIP status with Under Review sub-status for approver action. Current: " + currentStatus + " (" + subStatus + ")"));
            }

            String decision = getString(body, "decision", "").toUpperCase();
            if (!List.of("YES", "NO").contains(decision)) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Decision must be 'YES' or 'NO'."));
            }

            TaskStatusMaster targetStatus = TaskStatusMaster.CLOSED;
            String targetSubStatus = getCompletionSubStatus(task.getEndDt());

            if ("NO".equals(decision)) {
                targetStatus = TaskStatusMaster.WIP;
                String rejectionType = getString(body, "rejectionType", "REASSIGN").toUpperCase();
                targetSubStatus = "REWORK".equals(rejectionType) ? "Rework" : "Reassign";

                if (body.get("targetEmpId") != null) {
                    task.setEmpId(Long.valueOf(body.get("targetEmpId").toString()));
                }
            }

            String eventRemarks = getString(body, "remarks", "");
            if ("NO".equals(decision)) {
                String prefix = "Rework".equals(targetSubStatus) ? "[Rejected - Approver]" : "[Reassigned - Approver]";
                String existingRem = task.getRemarks();
                String newRem = prefix + ": " + eventRemarks;
                if (existingRem != null && !existingRem.trim().isEmpty()) {
                    newRem = existingRem + "\n---\n" + newRem;
                }
                task.setRemarks(newRem);
            }
            task.setTaskSts(targetStatus);
            task.setSubStatus(targetSubStatus);
            if ("NO".equals(decision)) {
                task.setPrcsYesActn(getString(body, "rejectionType", "REASSIGN").toUpperCase());
            } else {
                task.setPrcsYesActn("NONE");
            }
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
            event.setRemarks(eventRemarks);

            applyCountsFromHistoryForIndividual(taskId, event, decision);
            processRepo.save(event);

            if ("NO".equals(decision)) {
                List<ChecklistMaster> checklists = checklistRepo.findByTaskIdAndIsLive(taskId, false);
                if (checklists != null && !checklists.isEmpty()) {
                    for (ChecklistMaster item : checklists) {
                        item.setChkSts(false);
                        item.setCompletedTs(null);
                    }
                    checklistRepo.saveAll(checklists);
                }
            }

            String message = "YES".equals(decision)
                    ? "Approver approved. Task CLOSED! 🎉"
                    : "Approver rejected. Task moved to WIP (" + targetSubStatus + ").";

            return ResponseEntity.ok(Map.of("taskSts", targetStatus.getStatusNm(), "subStatus", targetSubStatus, "message", message));
        }
    }

    private String getCompletionSubStatus(java.time.LocalDate endDt) {
        if (endDt == null) return "On Time";
        java.time.LocalDate today = java.time.LocalDate.now();
        if (today.isBefore(endDt)) {
            return "Lead";
        } else if (today.isAfter(endDt)) {
            return "Lag";
        } else {
            return "On Time";
        }
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private Integer getRoleIdForRole(String role) {
        String roleName = "REVIEWER".equalsIgnoreCase(role) ? "Reviewer" : ("EXECUTOR".equalsIgnoreCase(role) ? "Executor" : "Approver");
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
