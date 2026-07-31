package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "department_master")
@Getter
@Setter
public class DepartmentMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "dept_id", columnDefinition = "smallserial")
    private Long deptId;

    @Column(name = "dept_nm", unique = true, nullable = false, length = 100)
    private String deptNm;

    @Column(name = "dept_code", unique = true, nullable = false, length = 10)
    private String deptCode;

    @Column(name = "descr", length = 255)
    private String descr;

    @Column(name = "sts")
    private Boolean sts;
}