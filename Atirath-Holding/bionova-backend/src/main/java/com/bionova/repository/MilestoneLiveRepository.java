package com.bionova.repository;

import com.bionova.entity.MilestoneLive;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MilestoneLiveRepository extends JpaRepository<MilestoneLive, Long> {
    List<MilestoneLive> findByPrjId(Long prjId);
    boolean existsByMlstnCd(String mlstnCd);
}
