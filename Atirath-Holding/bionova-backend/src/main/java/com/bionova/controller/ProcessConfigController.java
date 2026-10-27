package com.bionova.controller;

import com.bionova.entity.ProcessConfig;
import com.bionova.entity.AppNotification;
import com.bionova.repository.ProcessConfigRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.AssignmentRepository;
import com.bionova.repository.AppNotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/process-config")
public class ProcessConfigController {

    @Autowired
    private ProcessConfigRepository processConfigRepo;

    @Autowired
    private com.bionova.repository.ReviewerMasterRepository reviewerMasterRepo;

    @Autowired
    private TaskLiveRepository taskLiveRepo;

    @Autowired
    private AssignmentRepository assignmentRepo;

    @Autowired
    private AppNotificationRepository appNotificationRepo;

    private Integer getRoleIdForConfig(ProcessConfig config) {
        String roleName = "Approver";
        if (config != null) {
            String type = config.getStepType();
            String label = config.getStepLabel();
            if ("REVIEWER".equalsIgnoreCase(type) || (label != null && label.toLowerCase().contains("reviewer"))) {
                roleName = "Reviewer";
            } else if ("APPROVER".equalsIgnoreCase(type) || (label != null && label.toLowerCase().contains("approver"))) {
                roleName = "Approver";
            } else if (config.getOrdrId() != null && config.getOrdrId() == 1) {
                roleName = "Reviewer";
            }
        }
        final String targetRole = roleName;
        return reviewerMasterRepo.findAll().stream()
                .filter(r -> targetRole.equalsIgnoreCase(r.getRNm()))
                .findFirst()
                .map(com.bionova.entity.ReviewerMaster::getRId)
                .orElseGet(() -> {
                    com.bionova.entity.ReviewerMaster rm = new com.bionova.entity.ReviewerMaster();
                    rm.setRNm(targetRole);
                    rm = reviewerMasterRepo.save(rm);
                    return rm.getRId();
                });
    }

    private void enrichProcessConfigs(List<ProcessConfig> configs) {
        if (configs == null || configs.isEmpty()) return;
        Map<Integer, String> roleMap = reviewerMasterRepo.findAll().stream()
                .collect(java.util.stream.Collectors.toMap(
                        com.bionova.entity.ReviewerMaster::getRId,
                        com.bionova.entity.ReviewerMaster::getRNm,
                        (v1, v2) -> v1
                ));
        for (ProcessConfig pc : configs) {
            if (pc.getRId() != null && roleMap.containsKey(pc.getRId())) {
                String rNm = roleMap.get(pc.getRId());
                if ("Reviewer".equalsIgnoreCase(rNm)) {
                    pc.setStepType("REVIEWER");
                    pc.setStepLabel("Reviewer");
                } else if ("Approver".equalsIgnoreCase(rNm)) {
                    pc.setStepType("APPROVER");
                    pc.setStepLabel("Approver");
                }
            }
        }
    }

    // ── GET single ─────────────────────────────────────────────────────────

    @GetMapping("/{pcId}")
    public ResponseEntity<ProcessConfig> getById(@PathVariable Integer pcId) {
        return processConfigRepo.findById(pcId)
                .map(pc -> {
                    enrichProcessConfigs(List.of(pc));
                    return ResponseEntity.ok(pc);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // ── DRAFT TASK Process Config ───────────────────────────────────────────

    /** Get all process steps defined for a Draft Task */
    @GetMapping("/draft-task/{drftTaskId}")
    public List<ProcessConfig> getDraftSteps(@PathVariable Long drftTaskId) {
        List<ProcessConfig> configs = processConfigRepo.findByTaskIdAndIsLiveOrderByOrdrIdAsc(drftTaskId, false);
        enrichProcessConfigs(configs);
        return configs;
    }

    /**
     * Add a process step to a Draft Task.
     */
    @PostMapping("/draft-task/{drftTaskId}")
    public ResponseEntity<?> addDraftStep(
            @PathVariable Long drftTaskId,
            @RequestBody ProcessConfig config) {

        // Validate empId is set (since normal employees are assigned as reviewers/approvers)
        if (config.getEmpId() == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "empId must be provided to assign an employee."));
        }

        // Set rId automatically based on config (stepType / stepLabel / ordrId)
        config.setRId(getRoleIdForConfig(config));

        // Prevent duplicate step order for same task
        if (config.getOrdrId() != null &&
                processConfigRepo.existsByTaskIdAndIsLiveAndOrdrId(drftTaskId, false, config.getOrdrId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Step order " + config.getOrdrId() + " already exists for this task."));
        }

        config.setTaskId(drftTaskId);
        config.setIsLive(false);

        ProcessConfig saved = processConfigRepo.save(config);
        enrichProcessConfigs(List.of(saved));
        return ResponseEntity.ok(saved);
    }

    // ── INDIVIDUAL TASK Process Config ──────────────────────────────────────

    @PostMapping({"/assignments/{empTaskId}/bulk", "/individual-task/{empTaskId}/bulk"})
    public ResponseEntity<?> bulkSaveIndividualTaskSteps(
            @PathVariable Long empTaskId,
            @RequestBody List<ProcessConfig> configs) {

        processConfigRepo.deleteByEmpTaskId(empTaskId);

        if (configs == null || configs.isEmpty()) {
            return ResponseEntity.ok(List.of());
        }

        List<ProcessConfig> saved = new java.util.ArrayList<>();
        for (ProcessConfig config : configs) {
            if (config.getEmpId() == null && config.getExtEmpId() == null) continue;
            config.setPcId(null);
            config.setRId(getRoleIdForConfig(config));
            config.setEmpTaskId(empTaskId);
            config.setTaskId(null);
            config.setIsLive(false);
            ProcessConfig s = processConfigRepo.save(config);
            s.setStepType(config.getStepType());
            s.setStepLabel(config.getStepLabel());
            sendAssignmentNotification(s);
            saved.add(s);
        }
        enrichProcessConfigs(saved);
        return ResponseEntity.ok(saved);
    }

    @PostMapping({"/assignments/{empTaskId}", "/individual-task/{empTaskId}"})
    public ResponseEntity<?> addIndividualTaskStep(
            @PathVariable Long empTaskId,
            @RequestBody ProcessConfig config) {

        if (config.getEmpId() == null && config.getExtEmpId() == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "empId or extEmpId must be provided to assign a reviewer/approver."));
        }

        // If step with same ordrId already exists for this assignment, update it
        List<ProcessConfig> existing = processConfigRepo.findByEmpTaskIdOrderByOrdrIdAsc(empTaskId);
        ProcessConfig target = null;
        for (ProcessConfig pc : existing) {
            if (config.getOrdrId() != null && config.getOrdrId().equals(pc.getOrdrId())) {
                target = pc;
                break;
            }
        }

        if (target != null) {
            target.setEmpId(config.getEmpId());
            target.setExtEmpId(config.getExtEmpId());
            target.setStepType(config.getStepType());
            target.setStepLabel(config.getStepLabel());
            target.setRId(getRoleIdForConfig(config));
            ProcessConfig saved = processConfigRepo.save(target);
            saved.setStepType(config.getStepType());
            saved.setStepLabel(config.getStepLabel());
            sendAssignmentNotification(saved);
            enrichProcessConfigs(List.of(saved));
            return ResponseEntity.ok(saved);
        } else {
            config.setRId(getRoleIdForConfig(config));
            config.setEmpTaskId(empTaskId);
            config.setTaskId(null); 
            config.setIsLive(false); // Does not matter as it uses empTaskId

            ProcessConfig saved = processConfigRepo.save(config);
            saved.setStepType(config.getStepType());
            saved.setStepLabel(config.getStepLabel());
            sendAssignmentNotification(saved);
            enrichProcessConfigs(List.of(saved));
            return ResponseEntity.ok(saved);
        }
    }

    @DeleteMapping({"/assignments/{empTaskId}", "/individual-task/{empTaskId}"})
    public ResponseEntity<Void> deleteIndividualTaskSteps(@PathVariable Long empTaskId) {
        processConfigRepo.deleteByEmpTaskId(empTaskId);
        return ResponseEntity.ok().build();
    }

    @GetMapping({"/assignments/{empTaskId}", "/individual-task/{empTaskId}"})
    public List<ProcessConfig> getIndividualTaskSteps(@PathVariable Long empTaskId) {
        List<ProcessConfig> configs = processConfigRepo.findByEmpTaskIdOrderByOrdrIdAsc(empTaskId);
        enrichProcessConfigs(configs);
        return configs;
    }

    // ── LIVE TASK Process Config (read-only — cloned during promotion) ──────

    /** Get all process steps for a Live Task (cloned from draft during promotion) */
    @GetMapping("/live-task/{taskId}")
    public List<ProcessConfig> getLiveSteps(@PathVariable Long taskId) {
        List<ProcessConfig> configs = processConfigRepo.findByTaskIdAndIsLiveOrderByOrdrIdAsc(taskId, true);
        enrichProcessConfigs(configs);
        return configs;
    }

    // ── UPDATE (draft step editing) ─────────────────────────────────────────

    @PutMapping("/{pcId}")
    public ResponseEntity<?> update(@PathVariable Integer pcId,
                                     @RequestBody ProcessConfig details) {

        ProcessConfig config = processConfigRepo.findById(pcId)
                .orElseThrow(() -> new RuntimeException("Process config not found: " + pcId));

        // Check for duplicate ordrId if changing it
        if (details.getOrdrId() != null &&
                !details.getOrdrId().equals(config.getOrdrId()) &&
                processConfigRepo.existsByTaskIdAndIsLiveAndOrdrId(config.getTaskId(), config.getIsLive(), details.getOrdrId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Step order " + details.getOrdrId() + " already exists for this task."));
        }

        config.setOrdrId(details.getOrdrId());
        config.setEmpId(details.getEmpId());
        config.setStepType(details.getStepType());
        config.setStepLabel(details.getStepLabel());
        config.setRId(getRoleIdForConfig(details));

        ProcessConfig saved = processConfigRepo.save(config);
        saved.setStepType(details.getStepType());
        saved.setStepLabel(details.getStepLabel());
        sendAssignmentNotification(saved);
        enrichProcessConfigs(List.of(saved));
        return ResponseEntity.ok(saved);
    }

    // ── DELETE ──────────────────────────────────────────────────────────────

    @DeleteMapping("/{pcId}")
    public ResponseEntity<Void> delete(@PathVariable Integer pcId) {
        processConfigRepo.deleteById(pcId);
        return ResponseEntity.ok().build();
    }

    private void sendAssignmentNotification(ProcessConfig config) {
        if (config.getEmpId() == null) {
            return;
        }
        String role = "REVIEWER".equalsIgnoreCase(config.getStepType()) ? "Reviewer" : "Approver";
        
        if (config.getEmpTaskId() != null) {
            // Assignment
            assignmentRepo.findById(config.getEmpTaskId()).ifPresent(task -> {
                AppNotification notification = new AppNotification();
                notification.setEmpId(config.getEmpId());
                notification.setTitle("Assigned as " + role + ": " + task.getTaskCd());
                notification.setMessage("You have been assigned as the " + role + " for assignment '" + task.getTaskNm() + "'.");
                notification.setEntityTyp("ASSIGNMENT");
                notification.setEntityId(task.getEmpTaskId());
                appNotificationRepo.save(notification);
            });
        } else if (config.getTaskId() != null && Boolean.TRUE.equals(config.getIsLive())) {
            // Live task
            taskLiveRepo.findById(config.getTaskId()).ifPresent(task -> {
                AppNotification notification = new AppNotification();
                notification.setEmpId(config.getEmpId());
                notification.setTitle("Assigned as " + role + ": " + task.getTaskCd());
                notification.setMessage("You have been assigned as the " + role + " for task '" + task.getTaskNm() + "'.");
                notification.setEntityTyp("TASK");
                notification.setEntityId(task.getTaskId());
                appNotificationRepo.save(notification);
            });
        }
    }
}
