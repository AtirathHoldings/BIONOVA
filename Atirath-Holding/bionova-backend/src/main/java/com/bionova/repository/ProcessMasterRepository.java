package com.bionova.repository;

import com.bionova.entity.ProcessMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProcessMasterRepository extends JpaRepository<ProcessMaster, Integer> {

    /** All process events for a task, ordered by step */
    List<ProcessMaster> findByTaskIdOrderByOrdrIdAsc(Long taskId);
}
