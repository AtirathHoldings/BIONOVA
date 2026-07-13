package com.bionova.repository;

import com.bionova.entity.TaskLive;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskLiveRepository extends JpaRepository<TaskLive, Long> {

    @Query("SELECT t FROM TaskLive t WHERE t.mId = :mId")
    List<TaskLive> findByMilestoneId(@Param("mId") Long mId);

    @Query("SELECT t FROM TaskLive t WHERE t.empId = :empId")
    List<TaskLive> findByEmpId(@Param("empId") Long empId);

    @Query("SELECT t FROM TaskLive t WHERE t.mId = :mId AND t.empId = :empId")
    List<TaskLive> findByMilestoneIdAndEmpId(@Param("mId") Long mId, @Param("empId") Long empId);

    @Query("SELECT t FROM TaskLive t WHERE t.empId = :empId OR t.taskId IN (SELECT pc.taskId FROM ProcessConfig pc WHERE pc.empId = :empId AND pc.isLive = true)")
    List<TaskLive> findTasksForEmployee(@Param("empId") Long empId);

    @Query("SELECT t FROM TaskLive t WHERE t.mId = :mId AND (t.empId = :empId OR t.taskId IN (SELECT pc.taskId FROM ProcessConfig pc WHERE pc.empId = :empId AND pc.isLive = true))")
    List<TaskLive> findByMilestoneIdAndEmployeeOrReviewer(@Param("mId") Long mId, @Param("empId") Long empId);

    @Query("SELECT t FROM TaskLive t WHERE t.depTaskId = :depTaskId")
    List<TaskLive> findByDepTaskId(@Param("depTaskId") Long depTaskId);

    @Query("SELECT COUNT(t) > 0 FROM TaskLive t " +
           "JOIN MilestoneLive m ON t.mId = m.mId " +
           "WHERE t.taskCd = :taskCd AND m.prjId = :prjId")
    boolean existsByTaskCdAndProject(@Param("taskCd") String taskCd, @Param("prjId") Long prjId);

    @Query("SELECT COUNT(t) > 0 FROM TaskLive t " +
           "JOIN MilestoneLive m ON t.mId = m.mId " +
           "WHERE t.taskCd = :taskCd AND m.prjId = :prjId AND t.taskId <> :taskId")
    boolean existsByTaskCdAndProjectAndTaskIdNot(@Param("taskCd") String taskCd, @Param("prjId") Long prjId, @Param("taskId") Long taskId);
}
