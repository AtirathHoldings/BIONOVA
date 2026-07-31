package com.bionova.repository;

import com.bionova.entity.CompanyMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CompanyRepository
        extends JpaRepository<CompanyMaster, Long> {

    boolean existsByCoyCd(String coyCd);
    boolean existsByGstNum(String gstNum);
    boolean existsByTanNum(String tanNum);
    boolean existsByPanNum(String panNum);
    boolean existsByCin(String cin);

    boolean existsByCoyCdAndCoyIdNot(String coyCd, Long coyId);
    boolean existsByGstNumAndCoyIdNot(String gstNum, Long coyId);
    boolean existsByTanNumAndCoyIdNot(String tanNum, Long coyId);
    boolean existsByPanNumAndCoyIdNot(String panNum, Long coyId);
    boolean existsByCinAndCoyIdNot(String cin, Long coyId);
}