package com.bionova.repository;

import com.bionova.entity.AttachmentMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AttachmentMasterRepository extends JpaRepository<AttachmentMaster, Integer> {

    /** All attachments for a task in a specific context (draft or live) */
    List<AttachmentMaster> findByTIdAndIsLive(Long tId, Boolean isLive);
}
