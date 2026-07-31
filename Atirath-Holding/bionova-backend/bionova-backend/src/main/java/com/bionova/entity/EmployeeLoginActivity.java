package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "employee_login_activity")
@Getter
@Setter
public class EmployeeLoginActivity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "activity_id")
    private Long activityId;

    @Column(name = "emp_id", nullable = false)
    private Long empId;

    @Column(name = "device_info", nullable = false, length = 100)
    private String deviceInfo;

    @Column(name = "login_dt", nullable = false)
    private LocalDateTime loginDt = LocalDateTime.now();

    @Column(name = "sts", nullable = false, length = 20)
    private String status = "Logged Out"; // 'Active', 'Logged Out'
}
