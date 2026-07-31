package com.bionova.service;

import com.bionova.entity.ActivityLog;
import com.bionova.repository.ActivityLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class ActivityLogService {

    @Autowired
    private ActivityLogRepository activityLogRepository;

    public void logStatusChange(String entityTyp, Long entityId, String statusFrom, String statusTo) {
        logActivity(entityTyp, entityId, statusFrom, statusTo);
    }

    public void logActivity(String entityTyp, Long entityId, String actionFrom, String actionTo) {
        ActivityLog log = new ActivityLog();
        log.setEntityTyp(entityTyp);
        log.setEntityId(entityId);
        log.setStatusFrom(actionFrom != null ? actionFrom : "N/A");
        log.setStatusTo(actionTo != null ? actionTo : "N/A");
        log.setLogDt(LocalDateTime.now());
        activityLogRepository.save(log);
    }

    public List<ActivityLog> getLogsForEntity(String entityTyp, Long entityId) {
        return activityLogRepository.findByEntityTypAndEntityId(entityTyp, entityId);
    }

    public List<ActivityLog> getAllLogs() {
        return activityLogRepository.findAll();
    }
}
