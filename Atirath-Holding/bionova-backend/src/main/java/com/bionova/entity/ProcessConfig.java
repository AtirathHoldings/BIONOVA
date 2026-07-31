package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

/**
 * Defines the process approval steps for a task — in both Draft and Live.
 *
 * isLive = false  → task_id = task_draft_master.drft_task_id  (planning)
 * isLive = true   → task_id = task_live_master.task_id        (execution)
 *
 * Each row is ONE step in the approval chain for a task.
 * Example: Task needs REVIEWER first (step 1), then APPROVER (step 2).
 *
 *   ordr_id=1, step_type='REVIEWER', emp_id=5,  r_id=null
 *   ordr_id=2, step_type='APPROVER', emp_id=8,  r_id=null
 *
 * During Draft → Live promotion, these config rows are cloned
 * with isLive=true linked to the new live task_id.
 *
 * Actual YES/NO decisions are stored in ProcessMaster (transaction log).
 */
@Entity
@Table(name = "process_config")
@Getter
@Setter
public class ProcessConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "pc_id")
    private Integer pcId;

    /**
     * FK to task:
     *   isLive=false → drft_task_id (task_draft_master)
     *   isLive=true  → task_id      (task_live_master)
     */
    @Column(name = "task_id")
    private Long taskId;

    @Column(name = "ext_emp_id")
    private Long extEmpId;

    @Column(name = "emp_task_id")
    private Long empTaskId;

    /** false = draft config  |  true = live config */
    @Column(name = "is_live", nullable = false)
    private Boolean isLive = false;

    /** Step sequence number (1 = first approver, 2 = second, ...) */
    @Column(name = "ordr_id", nullable = false)
    private Integer ordrId;

    /** FK → employee_master.emp_id (checker employee, if CHECKER step) */
    @Column(name = "emp_id")
    private Long empId;

    /** FK → reviewer_master.r_id (reviewer, if REVIEWER step) */
    @Column(name = "r_id")
    private Integer rId;

    public String getStepType() {
        return (ordrId != null && ordrId == 1) ? "REVIEWER" : "APPROVER";
    }

    public void setStepType(String stepType) {
        // No-op
    }

    public String getStepLabel() {
        return (ordrId != null && ordrId == 1) ? "Reviewer" : "Approver";
    }

    public void setStepLabel(String stepLabel) {
        // No-op
    }
}
