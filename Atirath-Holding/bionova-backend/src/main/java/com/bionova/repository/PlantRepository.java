package com.bionova.repository;

import com.bionova.entity.PlantMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlantRepository
        extends JpaRepository<PlantMaster, Long> {

    List<PlantMaster> findByCoyId(Long coyId);

    boolean existsByPltCd(String pltCd);

    boolean existsByPltCdAndPltIdNot(String pltCd, Long pltId);
}