package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "app_notifications")
@Getter
@Setter
public class AppNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "emp_id")
    private Long empId;

    @Column(name = "title", nullable = false, length = 150)
    private String title;

    @Column(name = "message", nullable = false, columnDefinition = "TEXT")
    private String message;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "is_read", nullable = false, columnDefinition = "boolean default false")
    private Boolean isRead = false;

    @Column(name = "entity_typ", length = 20)
    private String entityTyp;

    @Column(name = "entity_id")
    private Long entityId;
}
