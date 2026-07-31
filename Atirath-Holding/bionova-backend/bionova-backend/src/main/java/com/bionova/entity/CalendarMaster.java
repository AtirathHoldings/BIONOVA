package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "calendar_master")
@org.hibernate.annotations.Check(constraints = "hol_typ IN ('MANDATORY','OPTIONAL')")
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

    // Scope fields removed as requested
    /**
     * MANDATORY = Public holiday (applies to all, regardless of cal_type)
     * OPTIONAL  = Optional holiday (company/plant/external specific)
     */
    @Column(name = "hol_typ", length = 10)
    private String holTyp;

    /** FK → employee_master.emp_id — who added this holiday record */
    @Column(name = "added_by")
    private Integer addedBy;

    @Column(name = "is_regular")
    private Boolean isRegular;
}
