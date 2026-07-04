package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "employee_individual_task_master")
@org.hibernate.annotations.Check(
        constraints =
                "priority IN ('HIGH','MEDIUM','NORMAL','LOW') " +
                        "AND task_asgn_to IN ('INTERNAL','EXTERNAL') " +
                        "AND task_sts IN ('DRAFT','ASSIGNED','OPEN','WIP','SUBMIT_REVIEW','UNDER_REVIEW','COMPLETED','REASSIGN')"
)
@Getter
@Setter
public class EmployeeIndividualTask {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "emp_task_id", columnDefinition = "smallserial")
    private Long empTaskId;

    @Column(name = "task_cd", nullable = false, unique = true, length = 10)
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

    @Column(name = "priority", length = 10)
    private String priority;

    @Column(name = "chk_flg")
    private Boolean chkFlg = false;

    @Column(name = "atta_flg")
    private Boolean attaFlg = false;

    @Column(name = "prcs_flg")
    private Boolean prcsFlg = false;

    @Column(name = "prcs_yes_actn", length = 200)
    private String prcsYesActn;

    @Column(name = "reviewer_id")
    private Integer reviewerId;

    @Column(name = "approver_id")
    private Long approverId;

    @Column(name = "task_sts", length = 20)
    private String taskSts = "DRAFT";

    @Column(name = "remarks", length = 255)
    private String remarks;

    @Column(name = "sts")
    private Boolean sts = true;

}