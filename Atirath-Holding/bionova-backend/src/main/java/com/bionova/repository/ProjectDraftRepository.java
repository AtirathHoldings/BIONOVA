package com.bionova.repository;

import com.bionova.entity.ProjectDraft;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProjectDraftRepository extends JpaRepository<ProjectDraft, Long> {

    List<ProjectDraft> findByCoyId(Integer coyId);

    List<ProjectDraft> findByPltId(Integer pltId);

    List<ProjectDraft> findByCoyIdAndPltId(Integer coyId, Integer pltId);
}
