package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "state_master")
@Getter
@Setter
public class StateMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "st_id")
    private Long stId;

    @Column(name = "st_cd", unique = true, length = 5)
    private String stCd;

    @Column(name = "zn_nm", nullable = false, length = 20)
    private String znNm;

    @Column(name = "st_nm", unique = true, length = 50)
    private String stNm;
}
