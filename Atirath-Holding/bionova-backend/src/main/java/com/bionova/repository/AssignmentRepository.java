package com.bionova.repository;

import com.bionova.entity.Assignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AssignmentRepository
        extends JpaRepository<Assignment, Long> {

    // Duplicate Task Code Validation (per employee)
    boolean existsByTaskCdAndEmpId(String taskCd, Long empId);

    boolean existsByTaskCdAndEmpIdAndEmpTaskIdNot(String taskCd, Long empId, Long empTaskId);

    // Employee Wise Tasks
    List<Assignment> findByEmpId(Long empId);

    @org.springframework.data.jpa.repository.Query("SELECT t FROM Assignment t WHERE t.empId = :empId OR t.empTaskId IN (SELECT pc.empTaskId FROM ProcessConfig pc WHERE pc.empId = :empId AND pc.empTaskId IS NOT NULL)")
    List<Assignment> findTasksForEmployee(@org.springframework.data.repository.query.Param("empId") Long empId);

    @org.springframework.data.jpa.repository.Query("SELECT t FROM Assignment t WHERE t.empId = :empId AND t.assignedBy != :empId")
    List<Assignment> findAssignedToMe(@org.springframework.data.repository.query.Param("empId") Long empId);

    @org.springframework.data.jpa.repository.Query("SELECT t FROM Assignment t WHERE t.assignedBy = :empId AND t.empId != :empId")
    List<Assignment> findAssignedByMe(@org.springframework.data.repository.query.Param("empId") Long empId);

    @org.springframework.data.jpa.repository.Query("SELECT t FROM Assignment t WHERE t.empId = :empId AND t.assignedBy = :empId")
    List<Assignment> findSelfAssigned(@org.springframework.data.repository.query.Param("empId") Long empId);

    // Assigned By
    List<Assignment> findByAssignedBy(Long assignedBy);

    // Status Wise
    List<Assignment> findByTaskSts(com.bionova.entity.TaskStatusMaster taskSts);

    // Priority Wise
    List<Assignment> findByPriority(com.bionova.entity.TaskPriorityMaster priority);

    // Employee + Status
    List<Assignment> findByEmpIdAndTaskSts(Long empId, com.bionova.entity.TaskStatusMaster taskSts);

    // Employee + Priority
    List<Assignment> findByEmpIdAndPriority(Long empId, com.bionova.entity.TaskPriorityMaster priority);

    // Active Tasks
    List<Assignment> findBySts(Boolean sts);

    // Employee + Active
    List<Assignment> findByEmpIdAndSts(Long empId, Boolean sts);

}
