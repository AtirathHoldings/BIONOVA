package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import com.bionova.enums.ProcessStatus;
import com.bionova.enums.TimeStatus;
import com.bionova.entity.ProjectLive;

@Entity
@Table(name = "task_live_master", indexes = {
        @Index(name = "idx_task_live_m_id", columnList = "m_id"),
        @Index(name = "idx_task_live_emp_id", columnList = "emp_id"),
        @Index(name = "idx_task_live_assigned_by", columnList = "assigned_by"),
        @Index(name = "idx_task_live_task_sts", columnList = "task_sts")
})
@org.hibernate.annotations.Check(constraints =
    "task_asgn_to IN ('INTERNAL','EXTERNAL') AND task_dep_typ IN ('INDEPENDENT','SEQUENTIAL','PARALLEL')")
@EntityListeners(com.bionova.config.AuditListener.class)
@Getter
@Setter
public class TaskLive {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "task_id")
    @com.fasterxml.jackson.annotation.JsonProperty("taskId")
    private Long taskId;

    @Column(name = "drft_task_id")
    @com.fasterxml.jackson.annotation.JsonProperty("drftTaskId")
    private Long drftTaskId;

    @Column(name = "m_id", nullable = false)
    @com.fasterxml.jackson.annotation.JsonProperty("mId")
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

    @Transient
    private Boolean isSequentialLocked = false;

    @Transient
    private String lockReason;

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

    @Transient
    private Long prjId;

    @Transient
    private String prjNm;

    @Transient
    private String mlstnCd;

    @Transient
    private String mlstnTtl;

    @Transient
    private String extEmpNm;

    @Transient
    private java.util.List<TeamMember> teamMembers;

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
        if (taskSts != null && ("CLOSED".equalsIgnoreCase(taskSts.getStatusNm()) || "COMPLETED".equalsIgnoreCase(taskSts.getStatusNm()))) {
            if (actCmpDt != null && endDt != null) {
                if (actCmpDt.isBefore(endDt)) {
                    return TimeStatus.LEAD;
                } else if (actCmpDt.isEqual(endDt)) {
                    return TimeStatus.ON_TIME;
                } else {
                    return TimeStatus.LAG;
                }
            } else if (endDt != null) {
                return TimeStatus.ON_TIME;
            }
        } else {
            if (endDt != null) {
                java.time.LocalDate today = java.time.LocalDate.now();
                if (today.isEqual(endDt)) {
                    return TimeStatus.DUE_TODAY;
                } else if (today.isAfter(endDt)) {
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

    public TaskPriorityMaster getRawPriority() {
        return this.priority;
    }

    public TaskPriorityMaster getPriority() {
        TaskPriorityMaster baseP = (this.priority != null) ? this.priority : TaskPriorityMaster.LOW;
        if (taskSts != null && "CLOSED".equalsIgnoreCase(taskSts.getStatusNm())) {
            return TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, taskSts, actCmpDt, baseP);
        }
        return TaskPriorityMaster.calculatePriority(stDt, endDt, noOfDays, taskSts, actCmpDt, baseP);
    }

    public void setAddlRem(String addlRem) {
        if (addlRem != null && addlRem.length() > 250) {
            this.addlRem = addlRem.substring(0, 250);
        } else {
            this.addlRem = addlRem;
        }
    }
}
