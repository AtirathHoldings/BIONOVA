package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

/**
 * Represents a team member assignment for a live task.
 *
 * One task can have multiple employees assigned via this table.
 * tm_id  → auto-generated PK (smallserial)
 * task_id → FK to task_live_master.task_id
 * emp_id  → FK to employee_master.emp_id
 * asgn_rmk → optional remark for the assignment
 */
@Entity
@Table(name = "team_members")
@Getter
@Setter
public class TeamMember {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "tm_id")
    private Integer tmId;

    @Column(name = "task_id", nullable = false)
    private Long taskId;

    @Column(name = "emp_id", nullable = false)
    private Long empId;

    @Column(name = "asgn_rmk", length = 255)
    private String asgnRmk;
}
