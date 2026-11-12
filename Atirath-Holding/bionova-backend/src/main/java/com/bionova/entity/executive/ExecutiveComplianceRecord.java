package com.bionova.entity.executive;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "executive_compliance_records")
@Getter
@Setter
public class ExecutiveComplianceRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "compliance_code", length = 50)
    private String complianceCode;

    @Column(name = "title", nullable = false, length = 255)
    private String title;

    @Column(name = "authority", length = 255)
    private String authority;

    @Column(name = "plant", length = 150)
    private String plant;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "license_no", length = 100)
    private String licenseNo;

    @Column(name = "issue_date", length = 50)
    private String issueDate;

    @Column(name = "expiry_date", length = 50)
    private String expiryDate;

    @Column(name = "esg_pillar", length = 50)
    private String esgPillar;

    @Column(name = "risk_level", length = 50)
    private String riskLevel;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "officer", length = 150)
    private String officer;

    @Column(name = "audit_score", length = 50)
    private String auditScore;
}

