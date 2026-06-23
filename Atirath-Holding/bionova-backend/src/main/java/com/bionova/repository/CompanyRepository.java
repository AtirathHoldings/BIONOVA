package com.bionova.repository;

import com.bionova.entity.CompanyMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CompanyRepository
        extends JpaRepository<CompanyMaster, Long> {
}