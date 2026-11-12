package com.bionova.repository.visitor;

import com.bionova.entity.visitor.VisitorSafetyClearance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VisitorSafetyClearanceRepository extends JpaRepository<VisitorSafetyClearance, Long> {
}

