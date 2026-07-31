package com.bionova.repository;

import com.bionova.entity.ScreenMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ScreenMasterRepository extends JpaRepository<ScreenMaster, Integer> {
    Optional<ScreenMaster> findByScreenCode(String screenCode);
}
