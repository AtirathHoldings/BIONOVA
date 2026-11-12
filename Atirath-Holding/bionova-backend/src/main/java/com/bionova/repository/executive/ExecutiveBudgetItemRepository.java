package com.bionova.repository.executive;

import com.bionova.entity.executive.ExecutiveBudgetItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExecutiveBudgetItemRepository extends JpaRepository<ExecutiveBudgetItem, Long> {
}

