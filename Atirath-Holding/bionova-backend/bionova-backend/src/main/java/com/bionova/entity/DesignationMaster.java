package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "designation_master")
@Getter
@Setter
public class DesignationMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "desig_id")
    private Integer desigId;

    @Column(name = "desig_cd", length = 50)
    private String desigCd;

    @Column(name = "desig_nm", nullable = false, length = 100)
    private String desigNm;

    @Column(name = "desig_desc", length = 255)
    private String desigDesc;

}
