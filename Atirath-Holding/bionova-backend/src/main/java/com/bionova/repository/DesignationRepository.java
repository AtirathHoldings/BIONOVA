package com.bionova.repository;

import com.bionova.entity.DesignationMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DesignationRepository
        extends JpaRepository<DesignationMaster, Integer> {
}
