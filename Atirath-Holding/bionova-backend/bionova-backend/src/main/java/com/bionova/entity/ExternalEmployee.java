package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "external_employee_master")
@Getter
@Setter
public class ExternalEmployee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ext_emp_id", columnDefinition = "smallserial")
    private Long extEmpId;

    @Column(name = "ext_emp_code", unique = true, length = 10)
    private String extEmpCode;

    @Column(name = "ext_emp_nm", nullable = false, length = 100)
    private String extEmpNm;

    @Column(name = "email", unique = true, length = 50)
    private String email;

    @Column(name = "mob_num", unique = true, length = 15)
    private String mobNum;

    @Column(name = "company_nm", nullable = false, length = 100)
    private String companyNm;

    @Column(name = "photo_path", length = 255)
    private String photoPath;

    @Column(name = "rep_emp_id")
    private Long repEmpId;

    @Column(name = "sts")
    private Boolean sts = true;
}
