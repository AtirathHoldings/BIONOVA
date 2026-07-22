package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import com.bionova.enums.ProcessStatus;
import com.bionova.enums.TimeStatus;
import com.bionova.entity.ProjectLive;

@Entity
@Table(name = "task_live_master")
@org.hibernate.annotations.Check(constraints =
    "task_asgn_to IN ('INTERNAL','EXTERNAL') AND task_dep_typ IN ('INDEPENDENT','SEQUENTIAL','PARALLEL')")
@EntityListeners(com.bionova.config.AuditListener.class)
@Getter
@Setter
public class TaskLive {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "task_id")
    private Long taskId;

    @Column(name = "drft_task_id")
    private Long drftTaskId;

    @Column(name = "m_id", nullable = false)
    private Long mId;

    @Column(name = "task_cd", unique = true, length = 10)
    private String taskCd;

    @Column(name = "task_nm", nullable = false, length = 100)
    private String taskNm;

    @Column(name = "task_desc", length = 255)
    private String taskDesc;

    @Column(name = "task_asgn_to", length = 10)
    private String taskAsgnTo;

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

    /** Working days excluding holidays */
    @Column(name = "wrk_days")
    private Integer wrkDays;

    @Column(name = "chk_flg")
    private Boolean chkFlg = false;

    @Column(name = "atta_flg")
    private Boolean attaFlg = false;

    @Column(name = "atta_file_id")
    private Integer attaFileId;

    @Column(name = "note_txt", length = 255)
    private String noteTxt;

    @Column(name = "st_dt", nullable = false)
    private LocalDate stDt;

    @Column(name = "end_dt")
    private LocalDate endDt;

    @Column(name = "act_cmp_dt")
    private LocalDate actCmpDt;

    @Column(name = "prcs_flg")
    private Boolean prcsFlg = false;

    @Column(name = "prcs_yes_actn", length = 200)
    private String prcsYesActn;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "task_sts", referencedColumnName = "status_id")
    private TaskStatusMaster taskSts = TaskStatusMaster.OPEN;

    @Column(name = "sub_status", length = 50)
    private String subStatus;

    @Transient
    private ProcessStatus processStatus; // NONE, UNDER_REVIEW, REWORK, REASSIGN

    @Transient
    private TimeStatus timeStatus; // LEAD, ON_TIME, DUE_TODAY, OVERDUE, LAG

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "priority", referencedColumnName = "priority_id")
    private TaskPriorityMaster priority;

    @Column(name = "addl_rem", length = 255)
    private String addlRem;

    @Transient
    private Long reviewer;

    @Transient
    private Long approver;

    @Transient
    private String reviewerNm;

    @Transient
    private String approverNm;

    public ProcessStatus getProcessStatus() {
        if (subStatus == null || subStatus.isEmpty()) {
            return ProcessStatus.NONE;
        }
        try {
            String normalized = subStatus.toUpperCase().replace(" ", "_");
            return ProcessStatus.valueOf(normalized);
        } catch (IllegalArgumentException e) {
            return ProcessStatus.NONE;
        }
    }

    public void setProcessStatus(ProcessStatus processStatus) {
        this.processStatus = processStatus;
        if (processStatus == null || processStatus == ProcessStatus.NONE) {
            this.subStatus = null;
        } else {
            String nm = processStatus.name().replace("_", " ");
            this.subStatus = capitalizeWords(nm);
        }
    }

    public TimeStatus getTimeStatus() {
        if (taskSts != null && "CLOSED".equalsIgnoreCase(taskSts.getStatusNm())) {
            if (actCmpDt != null && endDt != null) {
                if (actCmpDt.isBefore(endDt)) {
                    return TimeStatus.LEAD;
                } else if (actCmpDt.isEqual(endDt)) {
                    return TimeStatus.ON_TIME;
                } else {
                    return TimeStatus.LAG;
                }
            }
        } else {
            if (endDt != null) {
                java.time.LocalDate today = java.time.LocalDate.now();
                if (today.isBefore(endDt)) {
                    return TimeStatus.ON_TIME;
                } else if (today.isEqual(endDt)) {
                    return TimeStatus.DUE_TODAY;
                } else {
                    return TimeStatus.OVERDUE;
                }
            }
        }
        return null;
    }

    private String capitalizeWords(String str) {
        if (str == null || str.isEmpty()) return str;
        String[] words = str.toLowerCase().split(" ");
        StringBuilder sb = new StringBuilder();
        for (String w : words) {
            if (!w.isEmpty()) {
                sb.append(Character.toUpperCase(w.charAt(0))).append(w.substring(1)).append(" ");
            }
        }
        return sb.toString().trim();
    }

    public TaskPriorityMaster getPriority() {
        if (taskSts != null && "CLOSED".equalsIgnoreCase(taskSts.getStatusNm())) {
            return this.priority != null ? this.priority : TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, taskSts, actCmpDt);
        }
        return TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, taskSts, actCmpDt);
    }

    @PrePersist
    @PreUpdate
    public void preSave() {
        this.priority = getPriority();
    }
}
