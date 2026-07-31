package com.bionova.repository;

import com.bionova.entity.TaskStatusMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TaskStatusMasterRepository extends JpaRepository<TaskStatusMaster, Integer> {
}
