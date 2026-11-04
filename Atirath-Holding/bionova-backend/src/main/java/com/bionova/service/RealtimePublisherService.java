package com.bionova.service;

import com.bionova.entity.AppNotification;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class RealtimePublisherService {

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    /**
     * Broadcasts a notification to all listeners and to the specific employee topic.
     */
    public void broadcastNotification(AppNotification notif) {
        if (notif == null) return;
        try {
            messagingTemplate.convertAndSend("/topic/notifications", notif);
            if (notif.getEmpId() != null) {
                messagingTemplate.convertAndSend("/topic/notifications/" + notif.getEmpId(), notif);
            }
        } catch (Exception e) {
            System.err.println("Failed to broadcast realtime notification: " + e.getMessage());
        }
    }

    /**
     * Broadcasts task state change to real-time subscribers.
     */
    public void broadcastTaskUpdate(Long taskId, String taskCd, String status) {
        try {
            Map<String, Object> payload = Map.of(
                    "type", "TASK_UPDATE",
                    "taskId", taskId != null ? taskId : 0,
                    "taskCd", taskCd != null ? taskCd : "",
                    "status", status != null ? status : "",
                    "timestamp", System.currentTimeMillis()
            );
            messagingTemplate.convertAndSend("/topic/tasks", payload);
            broadcastDashboardRefresh();
        } catch (Exception e) {
            System.err.println("Failed to broadcast task update: " + e.getMessage());
        }
    }

    /**
     * Broadcasts a ping for dashboards to refresh their metrics.
     */
    public void broadcastDashboardRefresh() {
        try {
            messagingTemplate.convertAndSend("/topic/dashboard-refresh", Map.of(
                    "type", "DASHBOARD_REFRESH",
                    "timestamp", System.currentTimeMillis()
            ));
        } catch (Exception e) {
            System.err.println("Failed to broadcast dashboard refresh: " + e.getMessage());
        }
    }
}

