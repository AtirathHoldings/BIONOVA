package com.bionova.entity.visitor;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "visitor_configurations")
@Getter
@Setter
public class VisitorConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "plant_name", length = 150)
    private String plantName;

    @Column(name = "max_pass_duration_hours")
    private Integer maxPassDurationHours;

    @Column(name = "gate_opening_time", length = 30)
    private String gateOpeningTime;

    @Column(name = "gate_closing_time", length = 30)
    private String gateClosingTime;

    @Column(name = "auto_overdue_threshold_minutes")
    private Integer autoOverdueThresholdMinutes;

    @Column(name = "require_govt_id")
    private Boolean requireGovtId;

    @Column(name = "require_safety_induction")
    private Boolean requireSafetyInduction;

    @Column(name = "require_host_approval_for_vendors")
    private Boolean requireHostApprovalForVendors;

    @Column(name = "blacklisted_visitors", columnDefinition = "TEXT")
    private String blacklistedVisitors; // JSON array of blacklisted records
}

