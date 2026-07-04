package com.bionova.repository;

import com.bionova.entity.EmployeeIndividualTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmployeeIndividualTaskRepository
        extends JpaRepository<EmployeeIndividualTask, Long> {

    // Duplicate Task Code Validation
    boolean existsByTaskCd(String taskCd);

    boolean existsByTaskCdAndEmpTaskIdNot(String taskCd, Long empTaskId);

    // Employee Wise Tasks
    List<EmployeeIndividualTask> findByEmpId(Long empId);

    // Assigned By
    List<EmployeeIndividualTask> findByAssignedBy(Long assignedBy);

    // Status Wise
    List<EmployeeIndividualTask> findByTaskSts(String taskSts);

    // Priority Wise
    List<EmployeeIndividualTask> findByPriority(String priority);

    // Employee + Status
    List<EmployeeIndividualTask> findByEmpIdAndTaskSts(Long empId, String taskSts);

    // Employee + Priority
    List<EmployeeIndividualTask> findByEmpIdAndPriority(Long empId, String priority);

    // Active Tasks
    List<EmployeeIndividualTask> findBySts(Boolean sts);

    // Employee + Active
    List<EmployeeIndividualTask> findByEmpIdAndSts(Long empId, Boolean sts);

}