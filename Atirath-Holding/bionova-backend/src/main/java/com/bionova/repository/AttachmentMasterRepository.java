package com.bionova.repository;

import com.bionova.entity.AttachmentMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AttachmentMasterRepository extends JpaRepository<AttachmentMaster, Integer> {

    /** All attachments for a task in a specific context (draft or live) */
    @Query("SELECT a FROM AttachmentMaster a WHERE a.tId = :tId AND a.isLive = :isLive")
    List<AttachmentMaster> findByTIdAndIsLive(@Param("tId") Long tId, @Param("isLive") Boolean isLive);
}
