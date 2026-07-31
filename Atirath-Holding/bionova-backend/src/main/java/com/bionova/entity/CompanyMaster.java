package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

@Entity
@Table(name = "company_master")
@Getter
@Setter
public class CompanyMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "coy_id")
    private Long coyId;

    @Column(name = "coy_cd", unique = true, length = 10)
    private String coyCd;

    @Column(name = "coy_nm", nullable = false, length = 100)
    private String coyNm;

    @Column(name = "prnt_coy_id")
    private Long prntCoyId;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "gst_num", unique = true, length = 20)
    private String gstNum;

    @Column(name = "tan_num", unique = true, length = 15)
    private String tanNum;

    @Column(name = "pan_num", unique = true, length = 15)
    private String panNum;

    @Column(name = "inc_dt")
    private LocalDate incDt;

    @Column(name = "cin", unique = true, length = 25)
    private String cin;

    @Column(name = "web_url", length = 100)
    private String webUrl;

    @Column(name = "logo", length = 255)
    private String logo;

    @Column(name = "str", length = 150)
    private String str;

    @Column(name = "ct_vlg", length = 30)
    private String ctVlg;

    @Column(name = "dist", length = 30)
    private String dist;

    @Column(name = "st_id")
    private Long stId;

    @Column(name = "zn_nm", nullable = false, length = 20)
    private String znNm;

    @Column(name = "pin", length = 6)
    private String pin;

    @Column(name = "wrk_days_per_wk")
    private Integer wrkDaysPerWk;

    @Column(name = "addl_rem", length = 255)
    private String addlRem;

    @Column(name = "sts")
    private Boolean sts;
}