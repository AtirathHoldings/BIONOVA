package com.bionova.repository.visitor;

import com.bionova.entity.visitor.VisitorRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VisitorRequestRepository extends JpaRepository<VisitorRequest, Long> {
}

