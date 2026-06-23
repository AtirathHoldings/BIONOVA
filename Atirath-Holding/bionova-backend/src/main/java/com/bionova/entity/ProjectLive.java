package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "project_live_master")
@Getter
@Setter
public class ProjectLive {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "prj_id")
    private Long prjId;

    /** Reference back to the Draft that was promoted */
    @Column(name = "drft_prj_id")
    private Integer drftPrjId;

    @Column(name = "prj_cd", unique = true, length = 10)
    private String prjCd;

    @Column(name = "prj_nm", nullable = false, length = 100)
    private String prjNm;

    @Column(name = "prj_desc", nullable = false, length = 255)
    private String prjDesc;

    @Column(name = "dept_id")
    private Integer deptId;

    @Column(name = "prj_prty", columnDefinition = "VARCHAR(10) CHECK (prj_prty IN ('HIGH','MEDIUM','NORMAL','LOW'))")
    private String prjPrty;

    @Column(name = "prj_sts", columnDefinition = "VARCHAR(20) CHECK (prj_sts IN ('LIVE','HOLD','CLOSED'))")
    private String prjSts;

    @Column(name = "st_dt", nullable = false)
    private LocalDate stDt;

    @Column(name = "end_dt")
    private LocalDate endDt;

    @Column(name = "no_of_days")
    private Integer noOfDays;

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
}
