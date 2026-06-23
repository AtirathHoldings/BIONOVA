package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "calendar_master")
@Getter
@Setter
public class CalendarMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "cl_id")
    private Long clId;

    @Column(name = "cal_dt", nullable = false)
    private LocalDate calDt;

    @Column(name = "holiday_nm", nullable = false, length = 100)
    private String holidayNm;

    @Column(name = "cal_yr", nullable = false)
    private Integer calYr;

    @Column(name = "coy_id")
    private Integer coyId;

    @Column(name = "plt_id")
    private Integer pltId;

    @Column(name = "hol_typ", columnDefinition = "VARCHAR(10) CHECK (hol_typ IN ('MANDATORY','OPTIONAL'))")
    private String holTyp;

    @Column(name = "addl_rem", length = 255)
    private String addlRem;

    @Column(name = "sts", columnDefinition = "BOOLEAN DEFAULT TRUE")
    private Boolean sts = true;
}
