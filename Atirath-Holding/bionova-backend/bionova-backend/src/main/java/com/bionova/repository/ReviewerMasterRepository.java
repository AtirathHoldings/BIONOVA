package com.bionova.repository;

import com.bionova.entity.ReviewerMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ReviewerMasterRepository extends JpaRepository<ReviewerMaster, Integer> {
}
