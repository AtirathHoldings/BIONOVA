package com.bionova.repository.visitor;

import com.bionova.entity.visitor.VisitorMaterialOutward;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VisitorMaterialOutwardRepository extends JpaRepository<VisitorMaterialOutward, Long> {
}

