package com.bionova.repository.dispatchlogistics;

import com.bionova.entity.dispatchlogistics.TransitTemperatureLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TransitTemperatureLogRepository extends JpaRepository<TransitTemperatureLog, Long> {
}
