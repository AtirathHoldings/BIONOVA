package com.bionova.repository;

import com.bionova.entity.ProjectLive;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProjectLiveRepository extends JpaRepository<ProjectLive, Long> {
    Optional<ProjectLive> findByDrftPrjId(Long drftPrjId);
    boolean existsByPrjCd(String prjCd);
    List<ProjectLive> findByCoyId(Integer coyId);
    List<ProjectLive> findByPltId(Integer pltId);
}
