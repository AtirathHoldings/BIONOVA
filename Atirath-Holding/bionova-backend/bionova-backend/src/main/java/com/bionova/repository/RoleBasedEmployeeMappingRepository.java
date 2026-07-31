package com.bionova.repository;

import com.bionova.entity.RoleBasedEmployeeMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoleBasedEmployeeMappingRepository extends JpaRepository<RoleBasedEmployeeMapping, Integer> {
    List<RoleBasedEmployeeMapping> findByEmpId(Long empId);
    List<RoleBasedEmployeeMapping> findByRoleId(Integer roleId);
    void deleteByEmpId(Long empId);
    void deleteByEmpIdAndRoleId(Long empId, Integer roleId);
}
