package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "milestone_draft_master")
@org.hibernate.annotations.Check(constraints = "mlstn_dep_typ IN ('INDEPENDENT','SEQUENTIAL','PARALLEL') AND mlstn_sts IN ('DRAFT')")
@EntityListeners(com.bionova.config.AuditListener.class)
@Getter
@Setter
public class MilestoneDraft {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "drft_m_id")
    private Long drftMId;

    @Column(name = "drft_prj_id", nullable = false)
    private Long drftPrjId;

    @Column(name = "mlstn_cd", length = 10)
    private String mlstnCd;

    @Column(name = "mlstn_ttl", nullable = false, length = 100)
    private String mlstnTtl;

    @Column(name = "mlstn_desc", length = 255)
    private String mlstnDesc;

    @Column(name = "mlstn_days")
    private Integer mlstnDays;

    @Column(name = "mlstn_dep_flg")
    private Boolean mlstnDepFlg = false;

    @Column(name = "mlstn_dep_typ", length = 15)
    private String mlstnDepTyp;

    @Column(name = "mlstn_dep_m_id")
    private Long mlstnDepMId;

    @Column(name = "tent_st_dt")
    private LocalDate tentStDt;

    @Column(name = "tent_end_dt")
    private LocalDate tentEndDt;

    @Column(name = "file_url", length = 255)
    private String fileUrl;

    @Column(name = "addl_rem", length = 255)
    private String addlRem;

    @Column(name = "mlstn_sts", length = 20)
    private String mlstnSts = "DRAFT";

    @Column(name = "sts")
    private Boolean sts = true;
}
