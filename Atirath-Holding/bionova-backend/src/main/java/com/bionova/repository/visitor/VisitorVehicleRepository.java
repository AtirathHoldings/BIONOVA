package com.bionova.repository.visitor;

import com.bionova.entity.visitor.VisitorVehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VisitorVehicleRepository extends JpaRepository<VisitorVehicle, Long> {
}

