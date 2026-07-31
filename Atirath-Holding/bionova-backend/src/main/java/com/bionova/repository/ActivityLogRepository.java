package com.bionova.repository;

import com.bionova.entity.ActivityLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ActivityLogRepository extends JpaRepository<ActivityLog, Long> {
    List<ActivityLog> findByEntityTypAndEntityId(String entityTyp, Long entityId);
    List<ActivityLog> findByProcessedFalse();
}
