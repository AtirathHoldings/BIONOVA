package com.bionova.repository;

import com.bionova.entity.TaskDraft;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskDraftRepository extends JpaRepository<TaskDraft, Long> {
    List<TaskDraft> findByDrftMId(Long drftMId);
    @Query("SELECT COUNT(t) > 0 FROM TaskDraft t " +
           "JOIN MilestoneDraft m ON t.drftMId = m.drftMId " +
           "WHERE t.taskCd = :taskCd AND m.drftPrjId = :drftPrjId")
    boolean existsByTaskCdAndProject(@Param("taskCd") String taskCd, @Param("drftPrjId") Long drftPrjId);

    @Query("SELECT COUNT(t) > 0 FROM TaskDraft t " +
           "JOIN MilestoneDraft m ON t.drftMId = m.drftMId " +
           "WHERE t.taskCd = :taskCd AND m.drftPrjId = :drftPrjId AND t.drftTaskId <> :drftTaskId")
    boolean existsByTaskCdAndProjectAndDrftTaskIdNot(@Param("taskCd") String taskCd, @Param("drftPrjId") Long drftPrjId, @Param("drftTaskId") Long drftTaskId);

    @Query("SELECT COUNT(t) FROM TaskDraft t " +
           "JOIN MilestoneDraft m ON t.drftMId = m.drftMId " +
           "WHERE m.drftPrjId = :drftPrjId")
    long countTasksByDrftPrjId(@Param("drftPrjId") Long drftPrjId);
}
