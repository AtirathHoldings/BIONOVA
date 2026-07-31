package com.bionova.repository;

import com.bionova.entity.TaskPriorityMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TaskPriorityMasterRepository extends JpaRepository<TaskPriorityMaster, Integer> {
}
