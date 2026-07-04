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

    boolean existsByTaskCd(String taskCd);

    @Query("SELECT COUNT(t) > 0 FROM TaskLive t WHERE t.taskCd = :taskCd AND t.taskId <> :taskId")
    boolean existsByTaskCdAndTaskIdNot(@Param("taskCd") String taskCd, @Param("taskId") Long taskId);
}
