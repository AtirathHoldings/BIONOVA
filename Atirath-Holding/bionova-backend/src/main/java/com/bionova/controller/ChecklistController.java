package com.bionova.controller;

import com.bionova.entity.ChecklistMaster;
import com.bionova.repository.ChecklistMasterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
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
        return expandCommaRows(checklistRepo.findByTaskIdAndIsLive(taskId, false));
    }

    /**
     * Create a SINGLE checklist item for a Draft Task.
     * If chk_nm contains comma-separated values (e.g. "Step 1,Step 2"),
     * each value is split and saved as an individual row.
     */
    @PostMapping("/draft-task/{taskId}")
    public ResponseEntity<?> createForDraftTask(
            @PathVariable Long taskId,
            @RequestBody ChecklistMaster item) {

        // If chk_nm has commas → expand into multiple rows automatically
        if (item.getChkNm() != null && item.getChkNm().contains(",")) {
            List<ChecklistMaster> saved = saveItemsSplit(item.getChkNm(), item.getChkDesc(),
                    item.getSeqNo(), taskId, false);
            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        }

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

    /**
     * Bulk-create checklist items for a Draft Task.
     *
     * Accepts a JSON array: [{"chkNm": "Step 1", "chkDesc": "..."}, ...]
     * Each item's chk_nm may also be comma-separated — it will be split.
     *
     * POST /api/checklists/draft-task/{taskId}/bulk
     */
    @PostMapping("/draft-task/{taskId}/bulk")
    public ResponseEntity<?> bulkCreateForDraftTask(
            @PathVariable Long taskId,
            @RequestBody List<ChecklistMaster> items) {

        if (items == null || items.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Request body must be a non-empty list."));
        }

        List<ChecklistMaster> saved = new ArrayList<>();
        int seq = 1;
        for (ChecklistMaster item : items) {
            if (item.getChkNm() == null || item.getChkNm().isBlank()) continue;
            // Each item's chk_nm might itself be comma-separated
            List<ChecklistMaster> rows = saveItemsSplit(
                    item.getChkNm(), item.getChkDesc(), seq, taskId, false);
            saved.addAll(rows);
            seq += rows.size();
        }

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("created", saved.size(), "items", saved));
    }

    // ── LIVE TASK Checklist ─────────────────────────────────────────────────

    /** Get all checklist items for a Live Task (includes items created in draft mode) */
    @GetMapping("/live-task/{taskId}")
    public List<ChecklistMaster> getLiveTaskItems(@PathVariable Long taskId) {
        return expandCommaRows(checklistRepo.findByTaskId(taskId));
    }

    /**
     * Bulk-create checklist items for a Live Task.
     *
     * POST /api/checklists/live-task/{taskId}/bulk
     * Body: [{"chkNm": "Step 1"}, {"chkNm": "Step 2,Step 3"}]
     */
    @PostMapping("/live-task/{taskId}/bulk")
    public ResponseEntity<?> bulkCreateForLiveTask(
            @PathVariable Long taskId,
            @RequestBody List<ChecklistMaster> items) {

        if (items == null || items.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Request body must be a non-empty list."));
        }

        List<ChecklistMaster> saved = new ArrayList<>();
        int seq = 1;
        for (ChecklistMaster item : items) {
            if (item.getChkNm() == null || item.getChkNm().isBlank()) continue;
            List<ChecklistMaster> rows = saveItemsSplit(
                    item.getChkNm(), item.getChkDesc(), seq, taskId, true);
            saved.addAll(rows);
            seq += rows.size();
        }

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of("created", saved.size(), "items", saved));
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

    // ── PRIVATE HELPERS ─────────────────────────────────────────────────────

    /**
     * Expands any row whose chk_nm contains commas into multiple virtual
     * ChecklistMaster objects (one per comma-separated token).
     *
     * This handles legacy data that was stored as "Step 1,Step 2" in a single row.
     * The first token reuses the original chk_id (so /complete and /reopen still work);
     * additional tokens get chk_id = null (read-only display, no completion toggle).
     *
     * Once the DB is clean (all rows have a single chk_nm), this is a no-op.
     */
    private List<ChecklistMaster> expandCommaRows(List<ChecklistMaster> rows) {
        List<ChecklistMaster> expanded = new ArrayList<>();
        int seq = 1;
        for (ChecklistMaster row : rows) {
            if (row.getChkNm() == null || !row.getChkNm().contains(",")) {
                row.setSeqNo(seq++);
                expanded.add(row);
                continue;
            }
            // Comma-separated legacy row — split it
            String[] parts = Arrays.stream(row.getChkNm().split(","))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toArray(String[]::new);

            for (int i = 0; i < parts.length; i++) {
                ChecklistMaster virtual = new ChecklistMaster();
                // Only the FIRST split token keeps the real chk_id so toggle endpoints work
                virtual.setChkId(i == 0 ? row.getChkId() : null);
                virtual.setTaskId(row.getTaskId());
                virtual.setIsLive(row.getIsLive());
                virtual.setChkCd(row.getChkCd());
                virtual.setChkNm(parts[i]);
                virtual.setChkDesc(row.getChkDesc());
                virtual.setChkSts(row.getChkSts());
                virtual.setCompletedTs(row.getCompletedTs());
                virtual.setSts(row.getSts());
                virtual.setSeqNo(seq++);
                expanded.add(virtual);
            }
        }
        return expanded;
    }

    /**
     * Splits a potentially comma-separated chkNm string into individual
     * ChecklistMaster rows and persists each one.
     *
     * Example: "Verify docs,Upload files" → 2 separate rows
     *
     * @param rawNm   raw chk_nm string (may contain commas)
     * @param desc    shared description applied to all split items
     * @param startSeq starting sequence number
     * @param taskId  FK to the task
     * @param isLive  true = live task, false = draft task
     * @return list of persisted ChecklistMaster records
     */
    private List<ChecklistMaster> saveItemsSplit(
            String rawNm, String desc, int startSeq, Long taskId, boolean isLive) {

        List<ChecklistMaster> result = new ArrayList<>();
        String[] parts = Arrays.stream(rawNm.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toArray(String[]::new);

        for (int i = 0; i < parts.length; i++) {
            ChecklistMaster row = new ChecklistMaster();
            row.setTaskId(taskId);
            row.setIsLive(isLive);
            row.setChkNm(parts[i]);
            row.setChkDesc(desc);
            row.setChkSts(false);
            row.setSts(true);
            row.setSeqNo(startSeq + i);
            result.add(checklistRepo.save(row));
        }
        return result;
    }

    // ── SUMMARY (useful for frontend badge) ────────────────────────────────

    /**
     * GET /api/checklists/live-task/{taskId}/summary
     * Returns: { total, completed, pending, allDone }
     */
    @GetMapping("/live-task/{taskId}/summary")
    public ResponseEntity<Map<String, Object>> getLiveTaskSummary(@PathVariable Long taskId) {
        List<ChecklistMaster> items = checklistRepo.findByTaskId(taskId);
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
