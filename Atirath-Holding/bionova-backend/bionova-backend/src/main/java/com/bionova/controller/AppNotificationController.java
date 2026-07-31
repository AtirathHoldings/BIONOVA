package com.bionova.controller;

import com.bionova.entity.AppNotification;
import com.bionova.entity.Employee;
import com.bionova.repository.AppNotificationRepository;
import com.bionova.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
public class AppNotificationController {

    @Autowired
    private AppNotificationRepository notificationRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @GetMapping
    public ResponseEntity<List<AppNotification>> getMyNotifications() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> ResponseEntity.ok(notificationRepository.findByEmpIdOrderByCreatedAtDesc(employee.getEmpId())))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/unread")
    public ResponseEntity<List<AppNotification>> getMyUnreadNotifications() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> ResponseEntity.ok(notificationRepository.findByEmpIdAndIsReadFalse(employee.getEmpId())))
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long id) {
        return notificationRepository.findById(id)
                .map(notification -> {
                    notification.setIsRead(true);
                    notificationRepository.save(notification);
                    return ResponseEntity.ok(Map.of("message", "Notification marked as read"));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/read-all")
    public ResponseEntity<?> markAllAsRead() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> {
                    List<AppNotification> unread = notificationRepository.findByEmpIdAndIsReadFalse(employee.getEmpId());
                    for (AppNotification notification : unread) {
                        notification.setIsRead(true);
                    }
                    notificationRepository.saveAll(unread);
                    return ResponseEntity.ok(Map.of("message", "All notifications marked as read"));
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
