package com.bionova.repository;

import com.bionova.entity.ProjectTaskExternalToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProjectTaskExternalTokenRepository extends JpaRepository<ProjectTaskExternalToken, Long> {

    Optional<ProjectTaskExternalToken> findByToken(String token);

    Optional<ProjectTaskExternalToken> findByTaskIdAndExtEmpId(Long taskId, Long extEmpId);

    List<ProjectTaskExternalToken> findByTaskId(Long taskId);

    void deleteByTaskId(Long taskId);
}
