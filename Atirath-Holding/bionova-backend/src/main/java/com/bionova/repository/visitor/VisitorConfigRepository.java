package com.bionova.repository.visitor;

import com.bionova.entity.visitor.VisitorConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VisitorConfigRepository extends JpaRepository<VisitorConfig, Long> {
}

