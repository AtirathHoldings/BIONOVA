package com.bionova.repository;

import com.bionova.entity.TeamMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TeamMemberRepository extends JpaRepository<TeamMember, Integer> {

    /** All team members assigned to a specific task */
    List<TeamMember> findByTaskId(Long taskId);

    /** All task assignments for a specific employee */
    List<TeamMember> findByEmpId(Long empId);

    /** Check if an employee is already assigned to a task (avoid duplicates) */
    @Query("SELECT COUNT(tm) > 0 FROM TeamMember tm WHERE tm.taskId = :taskId AND tm.empId = :empId")
    boolean existsByTaskIdAndEmpId(@Param("taskId") Long taskId, @Param("empId") Long empId);

    /** Delete all members of a task (used when replacing the entire team) */
    void deleteByTaskId(Long taskId);
}
