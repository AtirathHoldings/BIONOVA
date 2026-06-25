package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * Stores YES/NO process-approval transactions for Live tasks.
 * Each row is one approval/rejection event from checker or reviewer.
 *
 * Flow:
 *   Task OPEN → WIP (employee starts work)
 *   Employee submits → SUBMIT_REVIEW
 *   Checker reviews → YES → UNDER_REVIEW (goes to reviewer)
 *                   → NO  → REWORK
 *   Reviewer reviews → YES → COMPLETED
 *                    → NO  → REWORK
 */
@Entity
@Table(name = "process_master")
@Getter
@Setter
public class ProcessMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pr_id")
    private Integer prId;

    /** Sequence / order of this process step */
    @Column(name = "ordr_id", nullable = false)
    private Integer ordrId;

    /** FK → task_live_master.task_id */
    @Column(name = "task_id", nullable = false)
    private Long taskId;

    /** FK → employee_master.emp_id (the checker/employee submitting) */
    @Column(name = "emp_id")
    private Long empId;

    /** FK → reviewer_master.r_id */
    @Column(name = "r_id")
    private Integer rId;

    /**
     * Role performing the action:
     *   CHECKER  = first-level checker (employee checks own work)
     *   REVIEWER = second-level reviewer (manager/reviewer approves)
     */
    @Column(name = "actor_role", length = 10)
    private String actorRole;  // 'CHECKER' | 'REVIEWER'

    /** Decision made: YES = approve, NO = reject */
    @Column(name = "prcs_sts", length = 3)
    private String prcsSts;    // 'YES' | 'NO'

    /** Running count of YES decisions for this task */
    @Column(name = "yes_cnt")
    private Integer yesCnt = 0;

    /** Running count of NO decisions for this task */
    @Column(name = "no_cnt")
    private Integer noCnt = 0;

    @Column(name = "remarks", length = 255)
    private String remarks;

    @Column(name = "remarks_ts")
    private LocalDateTime remarksTs;

    @PrePersist
    protected void onCreate() {
        if (remarksTs == null) {
            remarksTs = LocalDateTime.now();
        }
    }
}
