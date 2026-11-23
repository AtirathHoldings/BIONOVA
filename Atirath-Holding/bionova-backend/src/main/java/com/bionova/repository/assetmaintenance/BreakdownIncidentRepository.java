package com.bionova.repository.assetmaintenance;

import com.bionova.entity.assetmaintenance.BreakdownIncident;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface BreakdownIncidentRepository extends JpaRepository<BreakdownIncident, Long> {
}
