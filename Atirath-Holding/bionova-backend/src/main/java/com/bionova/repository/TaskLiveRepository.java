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

    boolean existsByTaskCd(String taskCd);
}
