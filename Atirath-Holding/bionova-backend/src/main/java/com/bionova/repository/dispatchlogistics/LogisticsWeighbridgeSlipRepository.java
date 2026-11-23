package com.bionova.repository.dispatchlogistics;

import com.bionova.entity.dispatchlogistics.LogisticsWeighbridgeSlip;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LogisticsWeighbridgeSlipRepository extends JpaRepository<LogisticsWeighbridgeSlip, Long> {
}
