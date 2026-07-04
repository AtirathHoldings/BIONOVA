package com.bionova.controller;

import com.bionova.entity.ProcessConfig;
import com.bionova.repository.ProcessConfigRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Process Config Controller — define WHO approves each task step (Draft & Live).
 *
 * ── DRAFT TASK ─────────────────────────────────────────────────────────────
 * POST   /api/process-config/draft-task/{drftTaskId}       → add a step
 * GET    /api/process-config/draft-task/{drftTaskId}       → list all steps
 * PUT    /api/process-config/{pcId}                        → update a step
 * DELETE /api/process-config/{pcId}                        → remove a step
 *
 * ── LIVE TASK ──────────────────────────────────────────────────────────────
 * GET    /api/process-config/live-task/{taskId}            → list live steps
 *        (live configs are auto-created during promotion; view only)
 *
 * ── EXAMPLE SETUP ──────────────────────────────────────────────────────────
 * Task TSK001 has prcsFlg=true, so add:
 *   Step 1: CHECKER  → emp_id=5  (quality checker)
 *   Step 2: REVIEWER → r_id=1    (manager sign-off)
 */
@RestController
@RequestMapping("/api/process-config")
public class ProcessConfigController {

    @Autowired
    private ProcessConfigRepository processConfigRepo;

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
     *
     * Body examples:
     *   CHECKER step:  { "ordrId": 1, "stepType": "CHECKER",  "empId": 5,    "stepLabel": "Quality Check" }
     *   REVIEWER step: { "ordrId": 2, "stepType": "REVIEWER", "rId": 1,      "stepLabel": "Manager Approval" }
     */
    @PostMapping("/draft-task/{drftTaskId}")
    public ResponseEntity<?> addDraftStep(
            @PathVariable Long drftTaskId,
            @RequestBody ProcessConfig config) {

        // Validate stepType
        if (!List.of("CHECKER", "REVIEWER").contains(config.getStepType())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "stepType must be 'CHECKER' or 'REVIEWER'."));
        }

        // Validate at least one of empId or rId is set
        if (config.getEmpId() == null && config.getRId() == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Either empId (for CHECKER) or rId (for REVIEWER) must be provided."));
        }

        // Prevent duplicate step order for same task
        if (config.getOrdrId() != null &&
                processConfigRepo.existsByTaskIdAndIsLiveAndOrdrId(drftTaskId, false, config.getOrdrId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Step order " + config.getOrdrId() + " already exists for this task."));
        }

        config.setTaskId(drftTaskId);
        config.setIsLive(false);

        return ResponseEntity.ok(processConfigRepo.save(config));
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

        if (!List.of("CHECKER", "REVIEWER").contains(details.getStepType())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "stepType must be 'CHECKER' or 'REVIEWER'."));
        }

        // Check for duplicate ordrId if changing it
        if (details.getOrdrId() != null &&
                !details.getOrdrId().equals(config.getOrdrId()) &&
                processConfigRepo.existsByTaskIdAndIsLiveAndOrdrId(config.getTaskId(), config.getIsLive(), details.getOrdrId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Step order " + details.getOrdrId() + " already exists for this task."));
        }

        config.setOrdrId(details.getOrdrId());
        config.setStepType(details.getStepType());
        config.setEmpId(details.getEmpId());
        config.setRId(details.getRId());
        config.setStepLabel(details.getStepLabel());

        return ResponseEntity.ok(processConfigRepo.save(config));
    }

    // ── DELETE ──────────────────────────────────────────────────────────────

    @DeleteMapping("/{pcId}")
    public ResponseEntity<Void> delete(@PathVariable Integer pcId) {
        processConfigRepo.deleteById(pcId);
        return ResponseEntity.ok().build();
    }
}
