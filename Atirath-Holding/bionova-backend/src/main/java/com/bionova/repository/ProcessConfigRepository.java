package com.bionova.repository;

import com.bionova.entity.ProcessConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProcessConfigRepository extends JpaRepository<ProcessConfig, Integer> {

    /** All process steps for a task in a given context, ordered by step */
    List<ProcessConfig> findByTaskIdAndIsLiveOrderByOrdrIdAsc(Long taskId, Boolean isLive);

    /** Check if a step order already exists for the same task+context */
    boolean existsByTaskIdAndIsLiveAndOrdrId(Long taskId, Boolean isLive, Integer ordrId);
}
