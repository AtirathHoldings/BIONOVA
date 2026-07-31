package com.bionova.controller;

import com.bionova.entity.ActivityLog;
import com.bionova.service.ActivityLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/activity-logs")
public class ActivityLogController {

    @Autowired
    private ActivityLogService activityLogService;

    @GetMapping
    public List<ActivityLog> getAllLogs() {
        return activityLogService.getAllLogs();
    }

    @GetMapping("/{entityTyp}/{entityId}")
    public ResponseEntity<List<ActivityLog>> getLogsForEntity(
            @PathVariable String entityTyp,
            @PathVariable Long entityId) {
        String normalizedType = entityTyp.toUpperCase();
        if (!List.of("PROJECT", "MILESTONE", "TASK").contains(normalizedType)) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(activityLogService.getLogsForEntity(normalizedType, entityId));
    }
}
