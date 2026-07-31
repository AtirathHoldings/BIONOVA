package com.bionova.repository;

import com.bionova.entity.AppNotification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface AppNotificationRepository extends JpaRepository<AppNotification, Long> {
    List<AppNotification> findByEmpIdAndIsReadFalse(Long empId);
    List<AppNotification> findByEmpIdOrderByCreatedAtDesc(Long empId);

    @org.springframework.data.jpa.repository.Query("SELECT COUNT(n) > 0 FROM AppNotification n WHERE n.empId = :empId AND n.title LIKE %:taskCd% AND n.createdAt >= :startOfDay")
    boolean existsReminderForToday(
        @org.springframework.data.repository.query.Param("empId") Long empId, 
        @org.springframework.data.repository.query.Param("taskCd") String taskCd, 
        @org.springframework.data.repository.query.Param("startOfDay") java.time.LocalDateTime startOfDay
    );

    java.util.Optional<AppNotification> findFirstByEntityTypAndEntityIdAndTitleContainingOrderByCreatedAtDesc(
        String entityTyp, Long entityId, String titlePart
    );
}
