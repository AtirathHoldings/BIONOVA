package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Checklist items linked to a Task (both Draft and Live task_id).
 * In Draft mode  → task_id references task_draft_master.drft_task_id
 * In Live mode   → task_id references task_live_master.task_id
 *
 * The 'is_live' flag distinguishes which context the record belongs to.
 */
@Entity
@Table(name = "checklist_master",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_chk_task_code",
                columnNames = {"task_id", "is_live", "chk_cd"}))
@Getter
@Setter
public class ChecklistMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "chk_id")
    private Integer chkId;

    /** FK to task (draft task_id or live task_id — distinguished by isLive flag) */
    @Column(name = "task_id", nullable = false)
    private Long taskId;

    /** true = this belongs to the live task; false = draft task */
    @Column(name = "is_live", nullable = false)
    private Boolean isLive = false;

    @Column(name = "chk_cd", unique = true, length = 10)
    private String chkCd;

    @Column(name = "chk_nm", nullable = false, length = 100)
    private String chkNm;

    @Column(name = "chk_desc", length = 255)
    private String chkDesc;

    /** Completion status: false = pending, true = completed */
    @Column(name = "chk_sts")
    private Boolean chkSts = false;

    @Column(name = "seq_no")
    private Integer seqNo;

    /** Timestamp when chk_sts flipped to true */
    @Column(name = "completed_ts")
    private LocalDateTime completedTs;

    /** Record active/inactive */
    @Column(name = "sts")
    private Boolean sts = true;
}
