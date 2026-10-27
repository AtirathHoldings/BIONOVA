package com.bionova.repository;

import com.bionova.entity.DepartmentMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DepartmentRepository
        extends JpaRepository<DepartmentMaster, Long> {
    boolean existsByDeptNmIgnoreCase(String deptNm);
    boolean existsByDeptNmIgnoreCaseAndDeptIdNot(String deptNm, Long deptId);
    boolean existsByDeptCodeIgnoreCase(String deptCode);
    boolean existsByDeptCodeIgnoreCaseAndDeptIdNot(String deptCode, Long deptId);
}