package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "calendar_master")
@org.hibernate.annotations.Check(constraints =
    "hol_typ IN ('MANDATORY','OPTIONAL') AND cal_type IN ('COMPANY','PLANT','EXTERNAL')")
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

    /**
     * Calendar scope:
     *   COMPANY  = company-wide holiday (all plants under this company)
     *   PLANT    = plant-specific holiday
     *   EXTERNAL = external business calendar
     * Null means it's a public/national holiday (MANDATORY), applies to all.
     */
    @Column(name = "cal_type", length = 10)
    private String calType;  // 'COMPANY' | 'PLANT' | 'EXTERNAL' | null

    /**
     * MANDATORY = Public holiday (applies to all, regardless of cal_type)
     * OPTIONAL  = Optional holiday (company/plant/external specific)
     */
    @Column(name = "hol_typ", length = 10)
    private String holTyp;

    /** FK → employee_master.emp_id — who added this holiday record */
    @Column(name = "added_by")
    private Integer addedBy;
}
