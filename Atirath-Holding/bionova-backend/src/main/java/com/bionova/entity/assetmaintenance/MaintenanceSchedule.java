package com.bionova.entity.assetmaintenance;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "maintenance_schedules")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class MaintenanceSchedule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "schedule_code", length = 50)
    private String scheduleCode;

    @Column(name = "asset_name", length = 150)
    private String assetName;

    @Column(name = "facility", length = 100)
    private String facility;

    @Column(name = "frequency", length = 100)
    private String frequency;

    @Column(name = "next_due_date", length = 50)
    private String nextDueDate;

    @Column(name = "meter_threshold_hrs")
    private Integer meterThresholdHrs;

    @Column(name = "checklist_items", columnDefinition = "TEXT")
    private String checklistItems;

    @Column(name = "lead_technician", length = 150)
    private String leadTechnician;

    @Column(name = "status", length = 50)
    private String status;
}
