package com.bionova.repository;

import com.bionova.entity.EmployeeIndividualTask;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmployeeIndividualTaskRepository extends JpaRepository<EmployeeIndividualTask, Long> {

    List<EmployeeIndividualTask> findByAssignedTo(Long assignedTo);

    List<EmployeeIndividualTask> findByAssignedBy(Long assignedBy);
}
