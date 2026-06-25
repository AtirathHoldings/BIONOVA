package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Stores file attachments for both Draft and Live tasks.
 *
 * isLive = false  → t_id references task_draft_master.drft_task_id
 * isLive = true   → t_id references task_live_master.task_id
 *
 * During Draft → Live promotion, draft attachments are cloned as
 * live attachments (isLive = true) linked to the new live task_id.
 */
@Entity
@Table(name = "attachments_master")
@Getter
@Setter
public class AttachmentMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "file_id")
    private Integer fileId;

    /**
     * FK to task ID.
     * When isLive=false → drft_task_id from task_draft_master
     * When isLive=true  → task_id from task_live_master
     */
    @Column(name = "t_id", nullable = false)
    private Long tId;

    /**
     * false = Draft task attachment
     * true  = Live task attachment (uploaded during live execution)
     */
    @Column(name = "is_live", nullable = false)
    private Boolean isLive = false;

    /** S3 URL or server file path */
    @Column(name = "at_path", nullable = false, length = 500)
    private String atPath;

    @Column(name = "file_nm", nullable = false, length = 255)
    private String fileNm;

    /** UPLOAD = directly uploaded file; ATTACHMENT = linked reference */
    @Column(name = "at_type", length = 20)
    private String atType;  // 'UPLOAD' | 'ATTACHMENT'

    @Column(name = "date_timestamp")
    private LocalDateTime dateTimestamp;

    @PrePersist
    protected void onCreate() {
        if (dateTimestamp == null) {
            dateTimestamp = LocalDateTime.now();
        }
    }
}
