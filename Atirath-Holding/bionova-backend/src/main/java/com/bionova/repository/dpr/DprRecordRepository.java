package com.bionova.repository.dpr;

import com.bionova.entity.dpr.DprRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DprRecordRepository extends JpaRepository<DprRecord, String> {
}
