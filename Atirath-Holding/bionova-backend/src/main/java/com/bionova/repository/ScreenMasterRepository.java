package com.bionova.repository;

import com.bionova.entity.ScreenMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ScreenMasterRepository extends JpaRepository<ScreenMaster, Integer> {
    List<ScreenMaster> findByStatus(Boolean status);
}
