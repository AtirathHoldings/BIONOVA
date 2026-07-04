package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDate;

@Entity
@Table(name = "employee_individual_task_master")
@org.hibernate.annotations.Check(constraints = 
    "priority IN ('HIGH','MEDIUM','NORMAL','LOW') AND task_sts IN ('ASSIGNED','IN_PROGRESS','COMPLETED','HOLD','CANCELLED')")
@Getter
@Setter
public class EmployeeIndividualTask {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "emp_task_id", columnDefinition = "smallserial")
    private Long empTaskId;

    @Column(name = "task_cd", unique = true, length = 10)
    private String taskCd;

    @Column(name = "task_nm", nullable = false, length = 100)
    private String taskNm;

    @Column(name = "task_desc", length = 255)
    private String taskDesc;

    @Column(name = "assigned_to", nullable = false)
    private Long assignedTo;

    @Column(name = "assigned_by", nullable = false)
    private Long assignedBy;

    @Column(name = "assigned_dt")
    private LocalDate assignedDt;

    @Column(name = "due_dt")
    private LocalDate dueDt;

    @Column(name = "to_be_completed_dt")
    private LocalDate toBeCompletedDt;

    @Column(name = "priority", length = 10)
    private String priority;

    @Column(name = "task_sts", length = 20)
    private String taskSts;

    @Column(name = "remarks", length = 255)
    private String remarks;

    @Column(name = "sts")
    private Boolean sts;
}
