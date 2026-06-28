package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "employee_settings")
@Getter
@Setter
public class EmployeeSettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "setting_id")
    private Long settingId;

    @Column(name = "emp_id", unique = true, nullable = false)
    private Long empId;

    @Column(name = "language", length = 20)
    private String language = "English";

    @Column(name = "date_format", length = 30)
    private String dateFormat = "DD-MMM-YYYY";

    @Column(name = "time_zone", length = 50)
    private String timeZone = "Asia/Kolkata";

    @Column(name = "theme", length = 20)
    private String theme = "Light";
}
