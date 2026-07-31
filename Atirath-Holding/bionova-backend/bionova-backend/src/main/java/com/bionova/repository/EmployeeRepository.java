package com.bionova.repository;

import com.bionova.entity.Employee;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EmployeeRepository
        extends JpaRepository<Employee, Long> {

    Optional<Employee> findByEmail(String email);

    boolean existsByEmpCode(String empCode);
    boolean existsByEmail(String email);
    boolean existsByMobNum(String mobNum);

    boolean existsByEmpCodeAndEmpIdNot(String empCode, Long empId);
    boolean existsByEmailAndEmpIdNot(String email, Long empId);
    boolean existsByMobNumAndEmpIdNot(String mobNum, Long empId);

    // Filter queries for employee listing
    List<Employee> findByCoyId(Integer coyId);
    List<Employee> findByCoyIdAndPltId(Integer coyId, Integer pltId);
    List<Employee> findByCoyIdAndPltIdAndDeptId(Integer coyId, Integer pltId, Integer deptId);
    List<Employee> findByCoyIdAndDeptId(Integer coyId, Integer deptId);
    List<Employee> findByPltId(Integer pltId);
    List<Employee> findByDeptId(Integer deptId);
}