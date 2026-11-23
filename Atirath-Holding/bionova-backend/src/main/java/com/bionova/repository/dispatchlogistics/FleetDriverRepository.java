package com.bionova.repository.dispatchlogistics;

import com.bionova.entity.dispatchlogistics.FleetDriver;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FleetDriverRepository extends JpaRepository<FleetDriver, Long> {
}
