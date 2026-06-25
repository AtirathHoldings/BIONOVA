package com.bionova.controller;

import com.bionova.entity.ChecklistMaster;
import com.bionova.repository.ChecklistMasterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Checklist Controller
 *
 * Draft Checklist:
 *   POST   /api/checklists/draft-task/{taskId}      → create checklist item for a draft task
 *   GET    /api/checklists/draft-task/{taskId}      → get all items for a draft task
 *
 * Live Checklist:
 *   GET    /api/checklists/live-task/{taskId}       → get all items for a live task
 *   PATCH  /api/checklists/{chkId}/complete         → mark an item as completed
 *   PATCH  /api/checklists/{chkId}/reopen           → reopen a completed item
 *
 * Common:
 *   GET    /api/checklists/{chkId}                  → get single item
 *   PUT    /api/checklists/{chkId}                  → update item (draft only)
 *   DELETE /api/checklists/{chkId}                  → delete item
 */
@RestController
@RequestMapping("/api/checklists")
public class ChecklistController {

    @Autowired
    private ChecklistMasterRepository checklistRepo;

    // ── GET single ─────────────────────────────────────────────────────────

    @GetMapping("/{chkId}")
    public ResponseEntity<ChecklistMaster> getById(@PathVariable Integer chkId) {
        return checklistRepo.findById(chkId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── DRAFT TASK Checklist ────────────────────────────────────────────────

    /** Get all checklist items for a Draft Task */
    @GetMapping("/draft-task/{taskId}")
    public List<ChecklistMaster> getDraftTaskItems(@PathVariable Long taskId) {
        return checklistRepo.findByTaskIdAndIsLive(taskId, false);
    }

    /** Create a checklist item for a Draft Task */
    @PostMapping("/draft-task/{taskId}")
    public ResponseEntity<?> createForDraftTask(
            @PathVariable Long taskId,
            @RequestBody ChecklistMaster item) {

        if (item.getChkCd() != null && !item.getChkCd().isBlank()
                && checklistRepo.existsByTaskIdAndIsLiveAndChkCd(taskId, false, item.getChkCd())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Checklist code already exists for this task."));
        }

        item.setTaskId(taskId);
        item.setIsLive(false);
        item.setChkSts(false);
        if (item.getSts() == null) item.setSts(true);

        return ResponseEntity.ok(checklistRepo.save(item));
    }

    // ── LIVE TASK Checklist ─────────────────────────────────────────────────

    /** Get all checklist items for a Live Task */
    @GetMapping("/live-task/{taskId}")
    public List<ChecklistMaster> getLiveTaskItems(@PathVariable Long taskId) {
        return checklistRepo.findByTaskIdAndIsLive(taskId, true);
    }

    /**
     * Mark a checklist item as COMPLETED.
     * Sets chk_sts = true and records the completion timestamp.
     */
    @PatchMapping("/{chkId}/complete")
    public ResponseEntity<?> markComplete(@PathVariable Integer chkId) {
        ChecklistMaster item = checklistRepo.findById(chkId)
                .orElseThrow(() -> new RuntimeException("Checklist item not found: " + chkId));

        item.setChkSts(true);
        item.setCompletedTs(LocalDateTime.now());
        return ResponseEntity.ok(checklistRepo.save(item));
    }

    /**
     * Reopen a checklist item (reset to pending).
     */
    @PatchMapping("/{chkId}/reopen")
    public ResponseEntity<?> reopen(@PathVariable Integer chkId) {
        ChecklistMaster item = checklistRepo.findById(chkId)
                .orElseThrow(() -> new RuntimeException("Checklist item not found: " + chkId));

        item.setChkSts(false);
        item.setCompletedTs(null);
        return ResponseEntity.ok(checklistRepo.save(item));
    }

    // ── UPDATE (draft editing) ──────────────────────────────────────────────

    @PutMapping("/{chkId}")
    public ResponseEntity<?> update(@PathVariable Integer chkId,
                                     @RequestBody ChecklistMaster details) {
        ChecklistMaster item = checklistRepo.findById(chkId)
                .orElseThrow(() -> new RuntimeException("Checklist item not found: " + chkId));

        if (details.getChkCd() != null && !details.getChkCd().isBlank()) {
            if (!details.getChkCd().equals(item.getChkCd())
                    && checklistRepo.existsByTaskIdAndIsLiveAndChkCd(item.getTaskId(), item.getIsLive(), details.getChkCd())) {
                return ResponseEntity.badRequest()
                        .body(Map.of("message", "Checklist code already exists for this task."));
            }
            item.setChkCd(details.getChkCd());
        }
        item.setChkNm(details.getChkNm());
        item.setChkDesc(details.getChkDesc());
        item.setSeqNo(details.getSeqNo());
        item.setSts(details.getSts());

        return ResponseEntity.ok(checklistRepo.save(item));
    }

    // ── DELETE ──────────────────────────────────────────────────────────────

    @DeleteMapping("/{chkId}")
    public ResponseEntity<Void> delete(@PathVariable Integer chkId) {
        checklistRepo.deleteById(chkId);
        return ResponseEntity.ok().build();
    }

    // ── SUMMARY (useful for frontend badge) ────────────────────────────────

    /**
     * GET /api/checklists/live-task/{taskId}/summary
     * Returns: { total, completed, pending, allDone }
     */
    @GetMapping("/live-task/{taskId}/summary")
    public ResponseEntity<Map<String, Object>> getLiveTaskSummary(@PathVariable Long taskId) {
        List<ChecklistMaster> items = checklistRepo.findByTaskIdAndIsLive(taskId, true);
        long total = items.stream().filter(i -> Boolean.TRUE.equals(i.getSts())).count();
        long completed = items.stream()
                .filter(i -> Boolean.TRUE.equals(i.getSts()) && Boolean.TRUE.equals(i.getChkSts()))
                .count();
        return ResponseEntity.ok(Map.of(
                "total", total,
                "completed", completed,
                "pending", total - completed,
                "allDone", total > 0 && completed == total
        ));
    }
}
