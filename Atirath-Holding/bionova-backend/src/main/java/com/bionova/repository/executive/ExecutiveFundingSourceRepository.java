package com.bionova.repository.executive;

import com.bionova.entity.executive.ExecutiveFundingSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExecutiveFundingSourceRepository extends JpaRepository<ExecutiveFundingSource, Long> {
}

