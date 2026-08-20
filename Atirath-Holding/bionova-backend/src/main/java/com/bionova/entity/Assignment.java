package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "employee_individual_task_master", indexes = {
        @Index(name = "idx_asgn_emp_id", columnList = "emp_id"),
        @Index(name = "idx_asgn_assigned_by", columnList = "assigned_by"),
        @Index(name = "idx_asgn_coy_id", columnList = "coy_id"),
        @Index(name = "idx_asgn_task_sts", columnList = "task_sts")
})
@org.hibernate.annotations.Check(
        constraints = "task_asgn_to IN ('INTERNAL','EXTERNAL')"
)
@Getter
@Setter
public class Assignment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "emp_task_id", columnDefinition = "smallserial")
    private Long empTaskId;

    @Column(name = "task_cd", nullable = false, length = 10)
    private String taskCd;

    @Column(name = "task_nm", nullable = false, length = 100)
    private String taskNm;

    @Column(name = "task_desc", length = 255)
    private String taskDesc;

    @Column(name = "emp_id", nullable = false)
    private Long empId;

    @Column(name = "assigned_by", nullable = false)
    private Long assignedBy;

    @Column(name = "task_asgn_to", length = 10)
    private String taskAsgnTo;

    @Column(name = "st_dt", nullable = false)
    private LocalDate stDt;

    @Column(name = "end_dt")
    private LocalDate endDt;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "priority", referencedColumnName = "priority_id")
    private TaskPriorityMaster priority;

    @Column(name = "chk_flg")
    private Boolean chkFlg = false;

    @Column(name = "atta_flg")
    private Boolean attaFlg = false;

    @Column(name = "prcs_flg")
    private Boolean prcsFlg = false;

    @Column(name = "prcs_yes_actn", length = 200)
    private String prcsYesActn;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "task_sts", referencedColumnName = "status_id")
    private TaskStatusMaster taskSts = TaskStatusMaster.DRAFT;

    @Column(name = "sub_status", length = 50)
    private String subStatus;

    @Column(name = "remarks", length = 255)
    private String remarks;

    @Column(name = "sts")
    private Boolean sts = true;

    @Transient
    private Long reviewer;

    @Transient
    private Long approver;

    @Transient
    private String reviewerNm;

    @Transient
    private String approverNm;

    @Transient
    private String empNm;

    @Transient
    private String assignedByNm;

    @Transient
    private java.util.List<TeamMember> teamMembers;

    @Transient
    private java.util.List<AttachmentMaster> attachments;

    @Transient
    private Integer attachmentCount = 0;

    @Transient
    private Integer checklistCount = 0;
}
