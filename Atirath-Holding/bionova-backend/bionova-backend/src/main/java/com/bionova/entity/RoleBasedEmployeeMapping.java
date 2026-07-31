package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "role_based_employee_mapping")
@Getter
@Setter
public class RoleBasedEmployeeMapping {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "map_id")
    private Integer mapId;

    @Column(name = "role_id", nullable = false)
    private Integer roleId;

    @Column(name = "emp_id", nullable = false)
    private Long empId;
}
