package com.bionova.repository;

import com.bionova.entity.ExternalEmployee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ExternalEmployeeRepository extends JpaRepository<ExternalEmployee, Long> {

    Optional<ExternalEmployee> findByEmail(String email);

    boolean existsByExtEmpCode(String extEmpCode);
    boolean existsByEmail(String email);
    boolean existsByMobNum(String mobNum);

    boolean existsByExtEmpCodeAndExtEmpIdNot(String extEmpCode, Long extEmpId);
    boolean existsByEmailAndExtEmpIdNot(String email, Long extEmpId);
    boolean existsByMobNumAndExtEmpIdNot(String mobNum, Long extEmpId);
}
