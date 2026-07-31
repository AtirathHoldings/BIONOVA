package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Entity
@Table(name = "activity_log_transaction")
@Getter
@Setter
public class ActivityLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "log_id")
    private Long logId;

    @Column(name = "entity_typ", nullable = false, length = 20)
    private String entityTyp;

    @Column(name = "entity_id", nullable = false)
    private Long entityId;

    @Column(name = "status_from", nullable = false, length = 20)
    private String statusFrom;

    @Column(name = "status_to", nullable = false, length = 20)
    private String statusTo;

    @Column(name = "log_dt", nullable = false)
    private LocalDateTime logDt = LocalDateTime.now();

    @Column(name = "processed", nullable = false, columnDefinition = "boolean default false")
    private Boolean processed = false;
}
