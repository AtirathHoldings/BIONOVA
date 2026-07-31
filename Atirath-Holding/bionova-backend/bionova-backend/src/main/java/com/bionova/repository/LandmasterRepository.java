package com.bionova.repository;

import com.bionova.entity.Landmaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface LandmasterRepository extends JpaRepository<Landmaster, Long> {

    boolean existsByLandCd(String landCd);

    boolean existsByLandCdAndLandIdNot(String landCd, Long landId);

}