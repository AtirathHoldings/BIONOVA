package com.bionova.repository;

import com.bionova.entity.MilestoneDraft;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MilestoneDraftRepository extends JpaRepository<MilestoneDraft, Long> {
    List<MilestoneDraft> findByDrftPrjId(Long drftPrjId);
    long countByDrftPrjId(Long drftPrjId);
    boolean existsByMlstnCdAndDrftPrjId(String mlstnCd, Long drftPrjId);
    boolean existsByMlstnCdAndDrftPrjIdAndDrftMIdNot(String mlstnCd, Long drftPrjId, Long drftMId);
}
