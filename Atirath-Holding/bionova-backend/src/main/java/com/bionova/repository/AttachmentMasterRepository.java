package com.bionova.repository;

import com.bionova.entity.AttachmentMaster;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AttachmentMasterRepository extends JpaRepository<AttachmentMaster, Integer> {

    // ── Legacy queries (backward compatibility) ──────────────────────────────

    /** All attachments for a task in a specific context (draft or live) */
    @Query("SELECT a FROM AttachmentMaster a WHERE a.tId = :tId AND a.isLive = :isLive")
    List<AttachmentMaster> findByTIdAndIsLive(@Param("tId") Long tId, @Param("isLive") Boolean isLive);

    // ── New ref-based queries ────────────────────────────────────────────────

    /** All attachments for any entity by refType and refId */
    @Query("SELECT a FROM AttachmentMaster a WHERE a.refId = :refId AND a.refType = :refType ORDER BY a.dateTimestamp DESC")
    List<AttachmentMaster> findByRefIdAndRefType(@Param("refId") Long refId, @Param("refType") String refType);

    /** All attachments for a live milestone */
    default List<AttachmentMaster> findByMilestoneId(Long mId) {
        return findByRefIdAndRefType(mId, "MILESTONE_LIVE");
    }

    /** All attachments for a live project */
    default List<AttachmentMaster> findByProjectId(Long prjId) {
        return findByRefIdAndRefType(prjId, "PROJECT_LIVE");
    }

    /** All attachments for a live task */
    default List<AttachmentMaster> findByLiveTaskId(Long taskId) {
        return findByRefIdAndRefType(taskId, "TASK_LIVE");
    }

    /** All attachments for a draft task */
    default List<AttachmentMaster> findByDraftTaskId(Long drftTaskId) {
        return findByRefIdAndRefType(drftTaskId, "TASK_DRAFT");
    }

    /** All attachments for an individual task / assignment */
    @Query("SELECT a FROM AttachmentMaster a WHERE " +
           "(a.refId = :empTaskId AND (a.refType IN ('ASSIGNMENT', 'TASK_ASSIGNMENT', 'TASK_INDIVIDUAL', 'INDIVIDUAL_TASK') OR a.refType IS NULL)) " +
           "OR (a.tId = :empTaskId AND (a.refType IN ('ASSIGNMENT', 'TASK_ASSIGNMENT', 'TASK_INDIVIDUAL', 'INDIVIDUAL_TASK') OR a.isLive = false)) " +
           "ORDER BY a.dateTimestamp DESC")
    List<AttachmentMaster> findByAssignmentTaskId(@Param("empTaskId") Long empTaskId);

    @Query("SELECT a FROM AttachmentMaster a WHERE " +
           "(a.refId IN :empTaskIds AND (a.refType IN ('ASSIGNMENT', 'TASK_ASSIGNMENT', 'TASK_INDIVIDUAL', 'INDIVIDUAL_TASK') OR a.refType IS NULL)) " +
           "OR (a.tId IN :empTaskIds AND (a.refType IN ('ASSIGNMENT', 'TASK_ASSIGNMENT', 'TASK_INDIVIDUAL', 'INDIVIDUAL_TASK') OR a.isLive = false)) " +
           "ORDER BY a.dateTimestamp DESC")
    List<AttachmentMaster> findByAssignmentTaskIds(@Param("empTaskIds") List<Long> empTaskIds);

    default List<AttachmentMaster> findByAssignmentId(Long empTaskId) {
        return findByAssignmentTaskId(empTaskId);
    }

    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Modifying
    @Query("DELETE FROM AttachmentMaster a WHERE (a.refId = :empTaskId AND (a.refType IN ('ASSIGNMENT', 'TASK_ASSIGNMENT', 'TASK_INDIVIDUAL', 'INDIVIDUAL_TASK') OR a.refType IS NULL)) OR (a.tId = :empTaskId AND (a.refType IN ('ASSIGNMENT', 'TASK_ASSIGNMENT', 'TASK_INDIVIDUAL', 'INDIVIDUAL_TASK') OR a.isLive = false))")
    void deleteByAssignmentTaskId(@Param("empTaskId") Long empTaskId);
}
