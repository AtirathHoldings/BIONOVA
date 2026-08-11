package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "project_task_external_tokens", indexes = {
        @Index(name = "idx_proj_ext_token_str", columnList = "token"),
        @Index(name = "idx_proj_ext_token_task_id", columnList = "task_id")
})
@Getter
@Setter
public class ProjectTaskExternalToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "token_id")
    private Long tokenId;

    @Column(name = "task_id", nullable = false)
    private Long taskId;

    @Column(name = "ext_emp_id", nullable = false)
    private Long extEmpId;

    @Column(name = "token", nullable = false, unique = true, length = 100)
    private String token;

    @Column(name = "expiry_dt", nullable = false)
    private LocalDateTime expiryDt;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "last_accessed_at")
    private LocalDateTime lastAccessedAt;

    @PrePersist
    public void prePersist() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
        if (this.isActive == null) {
            this.isActive = true;
        }
    }
}
