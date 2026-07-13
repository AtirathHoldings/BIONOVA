package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "project_live_master")
@org.hibernate.annotations.Check(constraints = "prj_sts IN ('LIVE','HOLD','CLOSED')")
@EntityListeners(com.bionova.config.AuditListener.class)
@Getter
@Setter
public class ProjectLive {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "prj_id")
    private Long prjId;

    @Column(name = "drft_prj_id")
    private Long drftPrjId;

    @Column(name = "prj_cd", unique = true, length = 10)
    private String prjCd;

    @Column(name = "prj_nm", nullable = false, length = 100)
    private String prjNm;

    @Column(name = "prj_desc", nullable = false, length = 255)
    private String prjDesc;

    @Column(name = "dept_id")
    private Integer deptId;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "prj_prty", referencedColumnName = "priority_id")
    private TaskPriorityMaster prjPrty;

    @Column(name = "prj_sts", length = 20)
    private String prjSts = "LIVE";

    @Column(name = "st_dt", nullable = false)
    private LocalDate stDt;

    @Column(name = "end_dt")
    private LocalDate endDt;

    @Column(name = "no_of_days")
    private Integer noOfDays;

    /** Number of working days excluding holidays */
    @Column(name = "wrk_days")
    private Integer wrkDays;

    @Column(name = "coy_id")
    private Integer coyId;

    @Column(name = "plt_id")
    private Integer pltId;

    @Column(name = "prj_objtv", nullable = false, length = 255)
    private String prjObjtv;

    @Column(name = "exp_dlvbls", length = 255)
    private String expDlvbls;

    @Column(name = "logo", length = 255)
    private String logo;

    @Column(name = "addl_rem", length = 255)
    private String addlRem;

    /**
     * Lead / On Time / Lag status for this project.
     * Values: "LEAD", "ON_TIME", "LAG"
     * Recalculated every time a task is completed.
     */
    @Column(name = "lead_lag_sts", length = 10)
    private String leadLagSts;

    /**
     * Actual completion date — set when all milestones/tasks are COMPLETED.
     * Used to determine LEAD (before endDt) or LAG (after endDt).
     */
    @Column(name = "act_cmp_dt")
    private java.time.LocalDate actCmpDt;

    @Transient
    private String location;

    @Transient
    private String clientName;

    @Transient
    private String plantName;
}
