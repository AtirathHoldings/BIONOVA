package com.bionova.repository;

import com.bionova.entity.EmployeeLoginActivity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmployeeLoginActivityRepository extends JpaRepository<EmployeeLoginActivity, Long> {
    List<EmployeeLoginActivity> findByEmpIdOrderByLoginDtDesc(Long empId);
}
