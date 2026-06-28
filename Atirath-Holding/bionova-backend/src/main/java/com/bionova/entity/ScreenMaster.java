package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "screen_master")
@Getter
@Setter
public class ScreenMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "screen_id")
    private Integer screenId;

    @Column(name = "screen_nm", nullable = false, length = 100)
    private String screenNm;

    @Column(name = "group_nm", nullable = false, length = 100)
    private String groupNm;

    @Column(name = "screen_code", unique = true, length = 50)
    private String screenCode;

    @Column(name = "sts")
    private Boolean status = true;
}
