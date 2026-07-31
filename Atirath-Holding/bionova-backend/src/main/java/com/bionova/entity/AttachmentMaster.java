package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Stores file attachments for Tasks, Milestones, and Projects.
 *
 * ── ref_type values ────────────────────────────────────────────────────────
 *   TASK_DRAFT      → ref_id = task_draft_master.drft_task_id
 *   TASK_LIVE       → ref_id = task_live_master.task_id
 *   MILESTONE_LIVE  → ref_id = milestone_live_master.m_id
 *   PROJECT_LIVE    → ref_id = project_live_master.prj_id
 *
 * ── at_type values ─────────────────────────────────────────────────────────
 *   UPLOAD     → file directly uploaded (stored in Supabase Storage)
 *   ATTACHMENT → linked reference / external URL
 *
 * ── bucket / storage location ──────────────────────────────────────────────
 *   Tasks       → documents/attachments/tasks/
 *   Milestones  → documents/attachments/milestones/
 *   Projects    → documents/attachments/projects/
 */
@Entity
@Table(name = "attachments_master")
@EntityListeners(com.bionova.config.AuditListener.class)
@Getter
@Setter
public class AttachmentMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "file_id")
    private Integer fileId;

    /**
     * Generic FK to the referenced entity ID.
     * Interpretation depends on ref_type:
     *   TASK_DRAFT     → drft_task_id
     *   TASK_LIVE      → task_id
     *   MILESTONE_LIVE → m_id
     *   PROJECT_LIVE   → prj_id
     *
     * @deprecated Use refId + refType instead of tId + isLive.
     */
    @Column(name = "t_id")
    private Long tId;

    /**
     * Reference entity ID (replaces tId for new records).
     * Kept nullable for backward-compatibility with existing task attachments.
     */
    @Column(name = "ref_id")
    private Long refId;

    /**
     * Type of entity this attachment belongs to.
     * Values: TASK_DRAFT | TASK_LIVE | MILESTONE_LIVE | PROJECT_LIVE
     */
    @Column(name = "ref_type", length = 20)
    private String refType;

    /**
     * Legacy flag for backward compatibility.
     * false = Draft task attachment, true = Live task attachment.
     * @deprecated Use refType = 'TASK_DRAFT' / 'TASK_LIVE' instead.
     */
    @Column(name = "is_live")
    private Boolean isLive;

    /** Public URL from Supabase Storage (or external URL for ATTACHMENT type) */
    @Column(name = "at_path", nullable = false, length = 500)
    private String atPath;

    @Column(name = "file_nm", nullable = false, length = 255)
    private String fileNm;

    /** UPLOAD = directly uploaded file to Supabase; ATTACHMENT = external link */
    @Column(name = "at_type", length = 20)
    private String atType;  // 'UPLOAD' | 'ATTACHMENT'

    @Column(name = "date_timestamp")
    private LocalDateTime dateTimestamp;

    @Column(name = "created_by", length = 100)
    private String createdBy;

    @PrePersist
    protected void onCreate() {
        if (dateTimestamp == null) {
            dateTimestamp = LocalDateTime.now();
        }
        // Back-fill legacy isLive for TASK_* types
        if (isLive == null && refType != null) {
            isLive = "TASK_LIVE".equals(refType);
        }
        // Back-fill tId for backward compatibility
        if (tId == null && refId != null) {
            tId = refId;
        }
    }
}
