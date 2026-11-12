package com.bionova.entity.executive;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "executive_project_pipeline")
@Getter
@Setter
public class ExecutiveProjectPipeline {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "project_code", length = 50)
    private String projectCode;

    @Column(name = "name", nullable = false, length = 200)
    private String name;

    @Column(name = "type", length = 100)
    private String type;

    @Column(name = "location", length = 255)
    private String location;

    @Column(name = "capacity", length = 100)
    private String capacity;

    @Column(name = "stage", length = 100)
    private String stage;

    @Column(name = "target_commissioning", length = 50)
    private String targetCommissioning;

    @Column(name = "start_date", length = 50)
    private String startDate;

    @Column(name = "completion_pct")
    private Double completionPct;

    @Column(name = "capex_approved")
    private Double capexApproved;

    @Column(name = "capex_spent")
    private Double capexSpent;

    @Column(name = "lead_pm", length = 150)
    private String leadPM;

    @Column(name = "status", length = 100)
    private String status;

    @Column(name = "upcoming_milestone", length = 255)
    private String upcomingMilestone;
}

