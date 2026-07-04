package com.bionova.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "land_master")
@Getter
@Setter
public class Landmaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "land_id")
    private Long landId;

    @Column(name = "land_cd", unique = true, length = 10)
    private String landCd;

    @Column(name = "plt_id")
    private Long pltId;

    @Column(name = "survey_no", length = 150)
    private String surveyNo;

    @Column(name = "land_owners", length = 100)
    private String landOwners;

    @Column(name = "mob_num", length = 15)
    private String mobNum;


    @Column(name = "land_size", precision = 12, scale = 2)
    private BigDecimal landSize;

    @Column(name = "alloted_for", length = 3)
    private String AllotedFor;

    @Column(name = "vlg", length = 50)
    private String vlg;

    @Column(name = "mdl", length = 30)
    private String mdl;

    @Column(name = "dist", length = 30)
    private String dist;

    @Column(name = "st_id")
    private Long stId;

    @Column(name = "pin", length = 6)
    private String pin;

    @Column(name = "lat", length = 20)
    private String lat;

    @Column(name = "longt", length = 20)
    private String longt;

    @Column(name = "sts")
    private Boolean sts;
}