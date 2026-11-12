package com.bionova.repository.executive;

import com.bionova.entity.executive.ExecutiveRevenueRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExecutiveRevenueRecordRepository extends JpaRepository<ExecutiveRevenueRecord, Long> {
}

