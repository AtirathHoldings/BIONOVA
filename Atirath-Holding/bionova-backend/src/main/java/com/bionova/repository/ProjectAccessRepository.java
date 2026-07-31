package com.bionova.repository;

import com.bionova.entity.ProjectAccess;
import com.bionova.entity.ProjectLive;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProjectAccessRepository extends JpaRepository<ProjectAccess, Long> {
    List<ProjectAccess> findByPrjIdAndSts(Long prjId, Boolean sts);
    Optional<ProjectAccess> findByPrjIdAndEmpId(Long prjId, Long empId);
    Optional<ProjectAccess> findByPrjIdAndEmpIdAndSts(Long prjId, Long empId, Boolean sts);
    List<ProjectAccess> findByEmpIdAndSts(Long empId, Boolean sts);

    @Query("SELECT p FROM ProjectLive p, ProjectAccess pa WHERE p.prjId = pa.prjId AND pa.empId = :empId AND pa.sts = true")
    List<ProjectLive> findProjectsByEmpId(@Param("empId") Long empId);
}
