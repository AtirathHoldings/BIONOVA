package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "dept_company_plt_map")
@Getter
@Setter
public class DeptCoyPltMap {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "map_id")
    private Long mapId;

    @Column(name = "dept_id", nullable = false)
    private Long deptId;

    @Column(name = "coy_id", nullable = false)
    private Long coyId;

    @Column(name = "plt_id", nullable = false)
    private Long pltId;

    @Column(name = "sts")
    private Boolean sts;
}
