package com.bionova.repository;

import com.bionova.entity.ChecklistMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChecklistMasterRepository extends JpaRepository<ChecklistMaster, Integer> {

    /** All checklist items for a given task (draft or live) */
    List<ChecklistMaster> findByTaskIdAndIsLive(Long taskId, Boolean isLive);

    /**
     * All checklist items for a task regardless of is_live flag.
     * Used for live-task fetch so that records created during draft mode
     * (is_live=false) are also returned after task goes live.
     */
    List<ChecklistMaster> findByTaskId(Long taskId);

    /** Count pending items (chkSts = false, active) for a live task */
    long countByTaskIdAndIsLiveAndChkStsAndSts(Long taskId, Boolean isLive, Boolean chkSts, Boolean sts);

    /** Check code uniqueness scoped to a specific task */
    boolean existsByTaskIdAndIsLiveAndChkCd(Long taskId, Boolean isLive, String chkCd);
}
