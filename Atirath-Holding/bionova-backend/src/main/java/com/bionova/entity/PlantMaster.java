package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "plant_master")
@Getter
@Setter
public class PlantMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "plt_id")
    private Long pltId;

    @Column(name = "plt_cd", unique = true, length = 10)
    private String pltCd;

    @Column(name = "coy_id")
    private Long coyId;

    @Column(name = "plt_nm", nullable = false, length = 100)
    private String pltNm;

    @Column(name = "cap")
    private Double cap;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "addr", length = 100)
    private String addr;

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

    @Column(name = "lat", length = 20)
    private String lat;

    @Column(name = "longt", length = 20)
    private String longt;

    @Column(name="logo",length=255)
    private String logo;

    @Column(name = "addl_rem", length = 255)
    private String addlRem;

    @Column(name = "sts")
    private Boolean sts;

    @com.fasterxml.jackson.annotation.JsonProperty("plantNm")
    public String getPlantNmAlias() {
        return this.pltNm;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("plantName")
    public String getPlantNameAlias() {
        return this.pltNm;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("plantId")
    public Long getPlantIdAlias() {
        return this.pltId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("id")
    public Long getIdAlias() {
        return this.pltId;
    }

    @com.fasterxml.jackson.annotation.JsonProperty("name")
    public String getNameAlias() {
        return this.pltNm;
    }
}