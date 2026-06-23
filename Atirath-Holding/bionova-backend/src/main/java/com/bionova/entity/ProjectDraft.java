package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "project_draft_master")
@Getter
@Setter
public class ProjectDraft {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
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

    @Column(name = "prj_prty", columnDefinition = "VARCHAR(10) CHECK (prj_prty IN ('HIGH','MEDIUM','NORMAL','LOW'))")
    private String prjPrty;

    @Column(name = "prj_sts", columnDefinition = "VARCHAR(20) CHECK (prj_sts IN ('DRAFT'))")
    private String prjSts;

    @Column(name = "tent_st_dt", nullable = false)
    private LocalDate tentStDt;

    @Column(name = "tent_end_dt", nullable = false)
    private LocalDate tentEndDt;

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
