package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "task_draft_master")
@org.hibernate.annotations.Check(constraints = "task_typ IN ('INTERNAL','EXTERNAL') AND task_dep_typ IN ('INDEPENDENT','SEQUENTIAL','PARALLEL')")
@EntityListeners(com.bionova.config.AuditListener.class)
@Getter
@Setter
public class TaskDraft {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "drft_task_id")
    private Long drftTaskId;

    @Column(name = "drft_m_id", nullable = false)
    private Long drftMId;

    @Column(name = "task_cd", length = 10)
    private String taskCd;

    @Column(name = "task_nm", nullable = false, length = 100)
    private String taskNm;

    @Column(name = "task_desc", length = 255)
    private String taskDesc;

    @Column(name = "task_typ", length = 10)
    private String taskTyp;

    @Column(name = "emp_id")
    private Long empId;

    @Column(name = "ext_emp_id")
    private Long extEmpId;

    @Column(name = "task_dep_flg")
    private Boolean taskDepFlg = false;

    @Column(name = "task_dep_typ", length = 15)
    private String taskDepTyp;

    @Column(name = "dep_task_id")
    private Long depTaskId;

    @Column(name = "no_of_days", nullable = false)
    private Integer noOfDays;

    @Column(name = "chk_flg")
    private Boolean chkFlg = false;

    @Column(name = "file_path", length = 255)
    private String filePath;

    @Column(name = "note_txt", length = 255)
    private String noteTxt;

    @Column(name = "tent_st_dt", nullable = false)
    private LocalDate tentStDt;

    @Column(name = "tent_end_dt", nullable = false)
    private LocalDate tentEndDt;

    @Column(name = "prcs_flg")
    private Boolean prcsFlg = false;

    @Column(name = "prcs_yes_actn", length = 200)
    private String prcsYesActn;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "task_sts", referencedColumnName = "status_id")
    private TaskStatusMaster taskSts = TaskStatusMaster.DRAFT;

    @Column(name = "sub_status", length = 50)
    private String subStatus;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "priority", referencedColumnName = "priority_id")
    private TaskPriorityMaster priority;

    @Column(name = "addl_rem", length = 255)
    private String addlRem;

    @Column(name = "sts")
    private Boolean sts = true;

    public TaskPriorityMaster getPriority() {
        if (taskSts != null && "CLOSED".equalsIgnoreCase(taskSts.getStatusNm())) {
            return this.priority != null ? this.priority : TaskPriorityMaster.calculatePriority(tentStDt, tentEndDt, noOfDays, taskSts, null);
        }
        return TaskPriorityMaster.calculatePriority(tentStDt, tentEndDt, noOfDays, taskSts, null);
    }

    @PrePersist
    @PreUpdate
    public void preSave() {
        this.priority = getPriority();
    }
}
