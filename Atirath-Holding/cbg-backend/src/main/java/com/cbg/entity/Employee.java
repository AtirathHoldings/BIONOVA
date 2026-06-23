package com.cbg.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

@Entity
@Table(name = "employee_master")
@SecondaryTable(
    name = "employee_password_master",
    pkJoinColumns = @PrimaryKeyJoinColumn(name = "emp_id", referencedColumnName = "emp_id")
)
@Getter
@Setter
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "emp_id")
    private Long empId;

    @Column(name = "emp_code", unique = true, length = 10)
    private String empCode;

    @Column(name = "fst_nm", nullable = false, length = 50)
    private String firstName;

    @Column(name = "lst_nm", length = 50)
    private String lastName;

    @Column(name = "gender", columnDefinition = "VARCHAR(10) CHECK (gender IN ('MALE','FEMALE','OTHER'))")
    private String gender;

    @Column(name = "dob", nullable = false)
    private LocalDate dob;

    @Column(name = "email", unique = true, length = 50)
    private String email;

    @Column(name = "mob_num", unique = true, length = 15)
    private String mobNum;

    @Column(name = "bld_grp", columnDefinition = "VARCHAR(5) CHECK (bld_grp IN ('A+','A-','B+','B-','AB+','AB-','O+','O-','Bombay','RH-Null'))")
    private String bldGrp;

    @Column(name = "address", nullable = false, length = 255)
    private String address;

    @Column(name = "photo_url", length = 255)
    private String photoUrl;

    @Column(name = "doj")
    private LocalDate doj;

    @Column(name = "desig_id")
    private Integer desigId;

    @Column(name = "coy_id")
    private Integer coyId;

    @Column(name = "plt_id")
    private Integer pltId;

    @Column(name = "dept_id")
    private Integer deptId;

    @Column(name = "w_loc", nullable = false, length = 100)
    private String wLoc;

    @Column(name = "rep_man_id")
    private Integer repManId;

    @Column(name = "sts")
    private Boolean status;

    @Column(name = "role", length = 20)
    private String role;

    @Column(name = "emp_password", table = "employee_password_master", nullable = false, length = 100)
    private String password;
}