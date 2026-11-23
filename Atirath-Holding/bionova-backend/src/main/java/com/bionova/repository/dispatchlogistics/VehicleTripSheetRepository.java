package com.bionova.repository.dispatchlogistics;

import com.bionova.entity.dispatchlogistics.VehicleTripSheet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleTripSheetRepository extends JpaRepository<VehicleTripSheet, Long> {
}
