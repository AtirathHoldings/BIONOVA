package com.bionova.repository;

import com.bionova.entity.EmployeeSettings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface EmployeeSettingsRepository extends JpaRepository<EmployeeSettings, Long> {
    Optional<EmployeeSettings> findByEmpId(Long empId);
}
