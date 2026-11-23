package com.bionova.repository.harvesting;

import com.bionova.entity.harvesting.HarvestBatch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface HarvestBatchRepository extends JpaRepository<HarvestBatch, String> {
}
