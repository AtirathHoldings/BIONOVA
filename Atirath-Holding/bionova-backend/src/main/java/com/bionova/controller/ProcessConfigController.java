package com.bionova.controller;

import com.bionova.entity.ProcessConfig;
import com.bionova.repository.ProcessConfigRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/process-config")
public class ProcessConfigController {

    @Autowired
    private ProcessConfigRepository processConfigRepo;

    @Autowired
    private com.bionova.repository.ReviewerMasterRepository reviewerMasterRepo;

    private Integer getRoleIdForOrder(Integer ordrId) {
        String roleName = (ordrId != null && ordrId == 1) ? "Reviewer" : "Approver";
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

    // ── GET single ─────────────────────────────────────────────────────────

    @GetMapping("/{pcId}")
    public ResponseEntity<ProcessConfig> getById(@PathVariable Integer pcId) {
        return processConfigRepo.findById(pcId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── DRAFT TASK Process Config ───────────────────────────────────────────

    /** Get all process steps defined for a Draft Task */
    @GetMapping("/draft-task/{drftTaskId}")
    public List<ProcessConfig> getDraftSteps(@PathVariable Long drftTaskId) {
        return processConfigRepo.findByTaskIdAndIsLiveOrderByOrdrIdAsc(drftTaskId, false);
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

        // Set rId automatically based on ordrId
        config.setRId(getRoleIdForOrder(config.getOrdrId()));

        // Prevent duplicate step order for same task
        if (config.getOrdrId() != null &&
                processConfigRepo.existsByTaskIdAndIsLiveAndOrdrId(drftTaskId, false, config.getOrdrId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Step order " + config.getOrdrId() + " already exists for this task."));
        }

        config.setTaskId(drftTaskId);
        config.setIsLive(false);

        ProcessConfig saved = processConfigRepo.save(config);
        return ResponseEntity.ok(saved);
    }

    // ── LIVE TASK Process Config (read-only — cloned during promotion) ──────

    /** Get all process steps for a Live Task (cloned from draft during promotion) */
    @GetMapping("/live-task/{taskId}")
    public List<ProcessConfig> getLiveSteps(@PathVariable Long taskId) {
        return processConfigRepo.findByTaskIdAndIsLiveOrderByOrdrIdAsc(taskId, true);
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
        config.setRId(getRoleIdForOrder(details.getOrdrId()));

        ProcessConfig saved = processConfigRepo.save(config);
        return ResponseEntity.ok(saved);
    }

    // ── DELETE ──────────────────────────────────────────────────────────────

    @DeleteMapping("/{pcId}")
    public ResponseEntity<Void> delete(@PathVariable Integer pcId) {
        processConfigRepo.deleteById(pcId);
        return ResponseEntity.ok().build();
    }
}
