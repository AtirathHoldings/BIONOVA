package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "milestone_live_master")
@org.hibernate.annotations.Check(constraints =
    "mlstn_dep_typ IN ('INDEPENDENT','SEQUENTIAL','PARALLEL') AND mlstn_sts IN ('LIVE','HOLD','COMPLETED','CLOSED')")
@Getter
@Setter
public class MilestoneLive {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "m_id")
    private Long mId;

    @Column(name = "drft_m_id")
    private Long drftMId;

    @Column(name = "prj_id", nullable = false)
    private Long prjId;

    @Column(name = "mlstn_cd", unique = true, length = 10)
    private String mlstnCd;

    @Column(name = "mlstn_ttl", nullable = false, length = 100)
    private String mlstnTtl;

    @Column(name = "mlstn_desc", length = 255)
    private String mlstnDesc;

    @Column(name = "mlstn_days")
    private Integer mlstnDays;

    /** Working days excluding holidays */
    @Column(name = "wrk_days")
    private Integer wrkDays;

    @Column(name = "mlstn_dep_flg")
    private Boolean mlstnDepFlg = false;

    @Column(name = "mlstn_dep_typ", length = 15)
    private String mlstnDepTyp;

    @Column(name = "mlstn_dep_m_id")
    private Long mlstnDepMId;

    @Column(name = "st_dt")
    private LocalDate stDt;

    @Column(name = "end_dt")
    private LocalDate endDt;

    @Column(name = "chk_id")
    private Integer chkId;

    @Column(name = "addl_rem", length = 255)
    private String addlRem;

    @Column(name = "mlstn_sts", length = 20)
    private String mlstnSts = "LIVE";

    @Column(name = "sts")
    private Boolean sts = true;
}
