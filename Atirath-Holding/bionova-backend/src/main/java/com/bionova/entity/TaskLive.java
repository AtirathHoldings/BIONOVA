package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "task_live_master")
@org.hibernate.annotations.Check(constraints =
    "task_asgn_to IN ('INTERNAL','EXTERNAL') AND task_dep_typ IN ('INDEPENDENT','SEQUENTIAL','PARALLEL') " +
    "AND task_sts IN ('OPEN','WIP','SUBMIT_REVIEW','UNDER_REVIEW','COMPLETED','REWORK')")
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

    @Column(name = "chk_id")
    private Integer chkId;

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

    @Column(name = "task_sts", length = 20)
    private String taskSts = "OPEN";

    @Column(name = "addl_rem", length = 255)
    private String addlRem;
}
