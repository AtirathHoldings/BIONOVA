package com.bionova.entity.visitor;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "visitor_records")
@Getter
@Setter
public class VisitorRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pass_no", unique = true, length = 50)
    private String passNo;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "phone", length = 50)
    private String phone;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "organization", length = 150)
    private String organization;

    @Column(name = "visitor_type", length = 50)
    private String visitorType;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;

    @Column(name = "host_employee", length = 150)
    private String hostEmployee;

    @Column(name = "department", length = 100)
    private String department;

    @Column(name = "purpose", length = 255)
    private String purpose;

    @Column(name = "expected_in_time", length = 30)
    private String expectedInTime;

    @Column(name = "expected_out_time", length = 30)
    private String expectedOutTime;

    @Column(name = "actual_in_time", length = 30)
    private String actualInTime;

    @Column(name = "actual_out_time", length = 30)
    private String actualOutTime;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "govt_id_type", length = 50)
    private String govtIdType;

    @Column(name = "govt_id", length = 100)
    private String govtId;

    @Column(name = "vehicle_type", length = 50)
    private String vehicleType;

    @Column(name = "vehicle_no", length = 50)
    private String vehicleNo;

    @Column(name = "safety_disclaimer_signed")
    private Boolean safetyDisclaimerSigned;

    @Column(name = "ppe_issued")
    private Boolean ppeIssued;

    @Column(name = "ppe_items", columnDefinition = "TEXT")
    private String ppeItems; // Stored as comma-separated or JSON string

    @Column(name = "badge_rfid", length = 50)
    private String badgeRfid;

    @Column(name = "assigned_zones", columnDefinition = "TEXT")
    private String assignedZones; // Stored as comma-separated or JSON string

    @Column(name = "escort_required")
    private Boolean escortRequired;

    @Column(name = "escort_name", length = 100)
    private String escortName;

    @Column(name = "is_overdue")
    private Boolean isOverdue;

    @Column(name = "overdue_minutes")
    private Integer overdueMinutes;

    @Column(name = "remarks", length = 255)
    private String remarks;
}

