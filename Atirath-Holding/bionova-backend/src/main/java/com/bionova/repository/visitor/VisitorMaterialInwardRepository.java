package com.bionova.repository.visitor;

import com.bionova.entity.visitor.VisitorMaterialInward;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VisitorMaterialInwardRepository extends JpaRepository<VisitorMaterialInward, Long> {
}

