package com.bionova.controller;

import com.bionova.entity.AttachmentMaster;
import com.bionova.repository.AttachmentMasterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Attachment Controller — stores files for both Draft and Live tasks.
 *
 * ── DRAFT TASK ────────────────────────────────────────────────────────
 * POST   /api/attachments/draft-task/{drftTaskId}   → add reference attachment to draft task
 * GET    /api/attachments/draft-task/{drftTaskId}   → list draft task attachments
 *
 * ── LIVE TASK ─────────────────────────────────────────────────────────
 * POST   /api/attachments/live-task/{taskId}        → upload/attach file during live execution
 * GET    /api/attachments/live-task/{taskId}        → list live task attachments
 *
 * ── COMMON ────────────────────────────────────────────────────────────
 * GET    /api/attachments/{fileId}                  → get single attachment
 * DELETE /api/attachments/{fileId}                  → delete attachment
 */
@RestController
@RequestMapping("/api/attachments")
public class AttachmentController {

    @Autowired
    private AttachmentMasterRepository attachmentRepo;

    // ── GET single ─────────────────────────────────────────────────────

    @GetMapping("/{fileId}")
    public ResponseEntity<AttachmentMaster> getById(@PathVariable Integer fileId) {
        return attachmentRepo.findById(fileId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── DRAFT TASK ──────────────────────────────────────────────────────

    /** List all attachments for a Draft Task */
    @GetMapping("/draft-task/{drftTaskId}")
    public List<AttachmentMaster> getDraftTaskAttachments(@PathVariable Long drftTaskId) {
        return attachmentRepo.findByTIdAndIsLive(drftTaskId, false);
    }

    /** Add a reference attachment to a Draft Task (e.g. design doc, spec sheet) */
    @PostMapping("/draft-task/{drftTaskId}")
    public ResponseEntity<?> addToDraftTask(
            @PathVariable Long drftTaskId,
            @RequestBody AttachmentMaster attachment) {

        ResponseEntity<?> validation = validate(attachment);
        if (validation != null) return validation;

        attachment.setTId(drftTaskId);
        attachment.setIsLive(false);
        return ResponseEntity.ok(attachmentRepo.save(attachment));
    }

    // ── LIVE TASK ───────────────────────────────────────────────────────

    /** List all attachments for a Live Task */
    @GetMapping("/live-task/{taskId}")
    public List<AttachmentMaster> getLiveTaskAttachments(@PathVariable Long taskId) {
        return attachmentRepo.findByTIdAndIsLive(taskId, true);
    }

    /**
     * Add an attachment to a Live Task.
     * Used when the employee uploads evidence/output files during task execution.
     */
    @PostMapping("/live-task/{taskId}")
    public ResponseEntity<?> addToLiveTask(
            @PathVariable Long taskId,
            @RequestBody AttachmentMaster attachment) {

        ResponseEntity<?> validation = validate(attachment);
        if (validation != null) return validation;

        attachment.setTId(taskId);
        attachment.setIsLive(true);
        return ResponseEntity.ok(attachmentRepo.save(attachment));
    }

    // ── DELETE ──────────────────────────────────────────────────────────

    @DeleteMapping("/{fileId}")
    public ResponseEntity<Void> delete(@PathVariable Integer fileId) {
        attachmentRepo.deleteById(fileId);
        return ResponseEntity.ok().build();
    }

    // ── Validation helper ───────────────────────────────────────────────

    private ResponseEntity<?> validate(AttachmentMaster a) {
        if (a.getAtPath() == null || a.getAtPath().isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Attachment path (at_path) is required."));
        }
        if (a.getFileNm() == null || a.getFileNm().isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "File name (file_nm) is required."));
        }
        if (!List.of("UPLOAD", "ATTACHMENT").contains(a.getAtType())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "at_type must be 'UPLOAD' or 'ATTACHMENT'."));
        }
        return null; // valid
    }
}
