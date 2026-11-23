package com.bionova.repository.assetmaintenance;

import com.bionova.entity.assetmaintenance.ServicingCostLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ServicingCostLogRepository extends JpaRepository<ServicingCostLog, Long> {
}
