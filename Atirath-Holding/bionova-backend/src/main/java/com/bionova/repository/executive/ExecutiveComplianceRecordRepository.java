package com.bionova.repository.executive;

import com.bionova.entity.executive.ExecutiveComplianceRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExecutiveComplianceRecordRepository extends JpaRepository<ExecutiveComplianceRecord, Long> {
}

