package com.bionova.entity.executive;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "executive_alerts")
@Getter
@Setter
public class ExecutiveAlert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "alert_code", length = 50)
    private String alertCode;

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "severity", length = 50)
    private String severity;

    @Column(name = "plant", length = 150)
    private String plant;

    @Column(name = "trigger_detail", columnDefinition = "TEXT")
    private String triggerDetail;

    @Column(name = "metric", length = 100)
    private String metric;

    @Column(name = "action", columnDefinition = "TEXT")
    private String action;

    @Column(name = "timestamp", length = 50)
    private String timestamp;

    @Column(name = "status", length = 50)
    private String status;
}

