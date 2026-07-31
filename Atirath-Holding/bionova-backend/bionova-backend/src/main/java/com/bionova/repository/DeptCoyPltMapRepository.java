package com.bionova.repository;

import com.bionova.entity.DeptCoyPltMap;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DeptCoyPltMapRepository extends JpaRepository<DeptCoyPltMap, Long> {

    List<DeptCoyPltMap> findByCoyId(Long coyId);

    List<DeptCoyPltMap> findByCoyIdAndPltId(Long coyId, Long pltId);

    boolean existsByDeptIdAndCoyIdAndPltId(Long deptId, Long coyId, Long pltId);

    boolean existsByDeptIdAndCoyIdAndPltIdAndMapIdNot(Long deptId, Long coyId, Long pltId, Long mapId);
}
