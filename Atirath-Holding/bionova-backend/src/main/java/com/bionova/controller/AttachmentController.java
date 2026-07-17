package com.bionova.controller;

import com.bionova.entity.AttachmentMaster;
import com.bionova.repository.AttachmentMasterRepository;
import com.bionova.service.SupabaseStorageService;
import com.bionova.service.ActivityLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Attachment Controller — stores file references (URLs) for Tasks, Milestones, and Projects.
 *
 * ── IMPORTANT ───────────────────────────────────────────────────────────────
 * Files are uploaded FIRST via StorageController (/api/storage/upload/...),
 * which returns a public URL. That URL is then POSTed here to be stored in
 * the attachments_master table linked to the entity.
 *
 * ── DRAFT TASK ────────────────────────────────────────────────────────────
 * POST   /api/attachments/draft-task/{drftTaskId}   → add attachment record
 * GET    /api/attachments/draft-task/{drftTaskId}   → list draft task attachments
 *
 * ── LIVE TASK ─────────────────────────────────────────────────────────────
 * POST   /api/attachments/live-task/{taskId}        → add attachment record
 * GET    /api/attachments/live-task/{taskId}        → list live task attachments
 *
 * ── MILESTONE ─────────────────────────────────────────────────────────────
 * POST   /api/attachments/milestone/{mId}           → add attachment to milestone
 * GET    /api/attachments/milestone/{mId}           → list milestone attachments
 *
 * ── PROJECT ───────────────────────────────────────────────────────────────
 * POST   /api/attachments/project/{prjId}           → add attachment to project
 * GET    /api/attachments/project/{prjId}           → list project attachments
 *
 * ── COMMON ────────────────────────────────────────────────────────────────
 * GET    /api/attachments/{fileId}                  → get single attachment
 * DELETE /api/attachments/{fileId}                  → delete attachment record + file from Supabase
 */
@RestController
@RequestMapping("/api/attachments")
public class AttachmentController {

    @Autowired
    private AttachmentMasterRepository attachmentRepo;

    @Autowired
    private SupabaseStorageService storageService;

    @Autowired
    private ActivityLogService activityLogService;

    @Autowired
    private com.bionova.repository.EmployeeRepository employeeRepository;

    private String getCurrentUserName() {
        try {
            org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
            if (auth != null && auth.getName() != null) {
                String email = auth.getName();
                com.bionova.entity.Employee employee = employeeRepository.findByEmail(email).orElse(null);
                if (employee != null) {
                    return employee.getFirstName() + " " + (employee.getLastName() != null ? employee.getLastName() : "");
                }
            }
        } catch (Exception e) {
            // fallback
        }
        return "System";
    }

    // ── GET single ─────────────────────────────────────────────────────────

    @GetMapping("/{fileId}")
    public ResponseEntity<AttachmentMaster> getById(@PathVariable Integer fileId) {
        return attachmentRepo.findById(fileId)
                .map(attachment -> {
                    activityLogService.logActivity("DOCUMENT", fileId.longValue(), "N/A", "DOWNLOADED");
                    return ResponseEntity.ok(attachment);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    // ── DRAFT TASK ──────────────────────────────────────────────────────────

    /** List all attachments for a Draft Task */
    @GetMapping("/draft-task/{drftTaskId}")
    public List<AttachmentMaster> getDraftTaskAttachments(@PathVariable Long drftTaskId) {
        List<AttachmentMaster> newStyle = attachmentRepo.findByDraftTaskId(drftTaskId);
        if (!newStyle.isEmpty()) return newStyle;
        // Fall back to legacy query for old records
        return attachmentRepo.findByTIdAndIsLive(drftTaskId, false);
    }

    /** Add a reference attachment to a Draft Task */
    @PostMapping("/draft-task/{drftTaskId}")
    public ResponseEntity<?> addToDraftTask(
            @PathVariable Long drftTaskId,
            @RequestBody AttachmentMaster attachment) {

        ResponseEntity<?> validation = validate(attachment);
        if (validation != null) return validation;

        attachment.setRefId(drftTaskId);
        attachment.setRefType("TASK_DRAFT");
        // Legacy fields for backward compat
        attachment.setTId(drftTaskId);
        attachment.setIsLive(false);
        attachment.setCreatedBy(getCurrentUserName());
        return ResponseEntity.ok(attachmentRepo.save(attachment));
    }

    // ── LIVE TASK ───────────────────────────────────────────────────────────

    /** List all attachments for a Live Task */
    @GetMapping("/live-task/{taskId}")
    public List<AttachmentMaster> getLiveTaskAttachments(@PathVariable Long taskId) {
        List<AttachmentMaster> newStyle = attachmentRepo.findByLiveTaskId(taskId);
        if (!newStyle.isEmpty()) return newStyle;
        // Fall back to legacy query for old records
        return attachmentRepo.findByTIdAndIsLive(taskId, true);
    }

    /** Add an attachment to a Live Task */
    @PostMapping("/live-task/{taskId}")
    public ResponseEntity<?> addToLiveTask(
            @PathVariable Long taskId,
            @RequestBody AttachmentMaster attachment) {

        ResponseEntity<?> validation = validate(attachment);
        if (validation != null) return validation;

        attachment.setRefId(taskId);
        attachment.setRefType("TASK_LIVE");
        // Legacy fields for backward compat
        attachment.setTId(taskId);
        attachment.setIsLive(true);
        attachment.setCreatedBy(getCurrentUserName());
        return ResponseEntity.ok(attachmentRepo.save(attachment));
    }

    // ── MILESTONE ───────────────────────────────────────────────────────────

    /** List all attachments for a Milestone */
    @GetMapping("/milestone/{mId}")
    public List<AttachmentMaster> getMilestoneAttachments(@PathVariable Long mId) {
        return attachmentRepo.findByMilestoneId(mId);
    }

    /**
     * Add a document attachment to a Milestone.
     * The at_path should be a URL obtained from:
     *   POST /api/storage/upload/attachment/milestone
     */
    @PostMapping("/milestone/{mId}")
    public ResponseEntity<?> addToMilestone(
            @PathVariable Long mId,
            @RequestBody AttachmentMaster attachment) {

        ResponseEntity<?> validation = validate(attachment);
        if (validation != null) return validation;

        attachment.setRefId(mId);
        attachment.setRefType("MILESTONE_LIVE");
        attachment.setCreatedBy(getCurrentUserName());
        return ResponseEntity.ok(attachmentRepo.save(attachment));
    }

    // ── PROJECT ─────────────────────────────────────────────────────────────

    /** List all attachments for a Project */
    @GetMapping("/project/{prjId}")
    public List<AttachmentMaster> getProjectAttachments(@PathVariable Long prjId) {
        return attachmentRepo.findByProjectId(prjId);
    }

    /**
     * Add a document attachment to a Project.
     * The at_path should be a URL obtained from:
     *   POST /api/storage/upload/attachment/project
     */
    @PostMapping("/project/{prjId}")
    public ResponseEntity<?> addToProject(
            @PathVariable Long prjId,
            @RequestBody AttachmentMaster attachment) {

        ResponseEntity<?> validation = validate(attachment);
        if (validation != null) return validation;

        attachment.setRefId(prjId);
        attachment.setRefType("PROJECT_LIVE");
        attachment.setCreatedBy(getCurrentUserName());
        return ResponseEntity.ok(attachmentRepo.save(attachment));
    }

    // ── DELETE ──────────────────────────────────────────────────────────────

    /**
     * Delete an attachment record by fileId.
     * Also deletes the actual file from Supabase Storage if at_type is 'UPLOAD'.
     */
    @DeleteMapping("/{fileId}")
    public ResponseEntity<Void> delete(@PathVariable Integer fileId) {
        attachmentRepo.findById(fileId).ifPresent(attachment -> {
            // Delete actual file from Supabase Storage for uploaded files
            if ("UPLOAD".equals(attachment.getAtType()) && attachment.getAtPath() != null) {
                storageService.deleteFileByUrl(attachment.getAtPath());
            }
            attachmentRepo.deleteById(fileId);
        });
        return ResponseEntity.ok().build();
    }

    // ── Validation helper ───────────────────────────────────────────────────

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
