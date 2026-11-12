package com.bionova.repository.executive;

import com.bionova.entity.executive.ExecutiveProjectPipeline;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExecutiveProjectPipelineRepository extends JpaRepository<ExecutiveProjectPipeline, Long> {
}

