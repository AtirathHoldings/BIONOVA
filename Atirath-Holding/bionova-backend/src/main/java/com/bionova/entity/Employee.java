package com.bionova.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
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
@org.hibernate.annotations.Check(constraints = "gender IN ('MALE','FEMALE','OTHER') AND bld_grp IN ('A+','A-','B+','B-','AB+','AB-','O+','O-','Bombay','RH-Null') AND emp_typ IN ('RET','FTE','CON')")
@Getter
@Setter
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "emp_id")
    private Long empId;

    @Column(name = "emp_code", unique = true, length = 10)
    private String empCode;

    @JsonProperty("fstNm")
    @Column(name = "fst_nm", nullable = false, length = 50)
    private String firstName;

    @JsonProperty("lstNm")
    @Column(name = "lst_nm", length = 50)
    private String lastName;

    @Column(name = "gender", length = 10)
    private String gender;

    @Column(name = "dob", nullable = false)
    private LocalDate dob;

    @Column(name = "email", unique = true, length = 50)
    private String email;

    @Column(name = "mob_num", unique = true, length = 15)
    private String mobNum;

    @Column(name = "bld_grp", length = 20)
    private String bldGrp;

    @Column(name = "address", nullable = false, length = 255)
    private String address;

    @Column(name = "photo_url", length = 255)
    private String photoUrl;

    @Column(name = "doj")
    private LocalDate doj;

    @Column(name = "emp_typ", length = 10)
    private String empTyp;

    @Column(name = "desig_id")
    private Integer desigId;

    @Column(name = "coy_id")
    private Integer coyId;

    @Column(name = "plt_id")
    private Integer pltId;

    @Column(name = "dept_id")
    private Integer deptId;

    @JsonProperty("wLoc")
    @Column(name = "w_loc", nullable = false, length = 100)
    private String wLoc;

    @Column(name = "rep_man_id")
    private Integer repManId;

    @JsonProperty("sts")
    @Column(name = "sts")
    private Boolean status;

    @Column(name = "fcm_token", length = 255)
    private String fcmToken;

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Column(name = "emp_password", table = "employee_password_master", nullable = false, length = 100)
    private String password;

    @Transient
    private String designation;

    @Transient
    private String role;
}