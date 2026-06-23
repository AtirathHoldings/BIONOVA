package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name="project_master")
@Getter
@Setter
public class Project {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="prj_id")
    private Long prjId;

    @Column(name="prj_nm")
    private String prjNm;

    @Column(name="prj_desc")
    private String prjDesc;

    @Column(name="prj_prty")
    private String prjPrty;

    @Column(name="prj_sts")
    private String prjSts;

    @Column(name="st_dt")
    private LocalDate stDt;

    @Column(name="end_dt")
    private LocalDate endDt;

    @Column(name="prj_objtv")
    private String prjObjtv;

    @Column(name="exp_dlvbls")
    private String expDlvbls;

    @Column(name="coy_id")
    private Long coyId;

    @Column(name="plt_id")
    private Long pltId;

    @Column(name="dept_id")
    private Long deptId;

    @Column(name="no_of_days")
    private Integer noOfDays;
}
