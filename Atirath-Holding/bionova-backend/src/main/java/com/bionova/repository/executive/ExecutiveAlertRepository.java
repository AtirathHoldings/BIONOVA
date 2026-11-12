package com.bionova.repository.executive;

import com.bionova.entity.executive.ExecutiveAlert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExecutiveAlertRepository extends JpaRepository<ExecutiveAlert, Long> {
}

