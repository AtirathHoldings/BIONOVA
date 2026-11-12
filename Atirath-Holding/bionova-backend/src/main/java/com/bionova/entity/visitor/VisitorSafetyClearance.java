package com.bionova.entity.visitor;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "visitor_safety_clearances")
@Getter
@Setter
public class VisitorSafetyClearance {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "clearance_code", length = 50)
    private String clearanceCode;

    @Column(name = "visitor_name", nullable = false, length = 150)
    private String visitorName;

    @Column(name = "organization", length = 150)
    private String organization;

    @Column(name = "inducted_by", length = 100)
    private String inductedBy;

    @Column(name = "induction_date", length = 30)
    private String inductionDate;

    @Column(name = "induction_time", length = 30)
    private String inductionTime;

    @Column(name = "hazard_briefing_completed")
    private Boolean hazardBriefingCompleted;

    @Column(name = "ppe_checklist", columnDefinition = "TEXT")
    private String ppeChecklist; // JSON or comma-separated

    @Column(name = "emergency_briefed")
    private Boolean emergencyBriefed;

    @Column(name = "status", length = 50)
    private String status;
}

