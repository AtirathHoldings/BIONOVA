package com.bionova.repository;

import com.bionova.entity.MilestoneLive;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

@Repository
public interface MilestoneLiveRepository extends JpaRepository<MilestoneLive, Long> {
    List<MilestoneLive> findByPrjId(Long prjId);
    boolean existsByMlstnCdAndPrjId(String mlstnCd, Long prjId);

    @Query("SELECT COUNT(m) > 0 FROM MilestoneLive m WHERE m.mlstnCd = :mlstnCd AND m.prjId = :prjId AND m.mId <> :mId")
    boolean existsByMlstnCdAndPrjIdAndMIdNot(@Param("mlstnCd") String mlstnCd, @Param("prjId") Long prjId, @Param("mId") Long mId);

    @Query("SELECT DISTINCT m FROM MilestoneLive m, TaskLive t WHERE m.mId = t.mId AND (t.empId = :empId OR t.taskId IN (SELECT pc.taskId FROM ProcessConfig pc WHERE pc.empId = :empId AND pc.isLive = true))")
    List<MilestoneLive> findMilestonesByEmpId(@Param("empId") Long empId);
}
