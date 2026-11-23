package com.bionova.entity.assetmaintenance;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "breakdown_incidents")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class BreakdownIncident {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "ticket_number", length = 50)
    private String ticketNumber;

    @Column(name = "facility", length = 100)
    private String facility;

    @Column(name = "asset_name", length = 150)
    private String assetName;

    @Column(name = "reported_time", length = 50)
    private String reportedTime;

    @Column(name = "severity", length = 100)
    private String severity;

    @Column(name = "symptom_description", columnDefinition = "TEXT")
    private String symptomDescription;

    @Column(name = "downtime_hours")
    private Double downtimeHours;

    @Column(name = "root_cause", columnDefinition = "TEXT")
    private String rootCause;

    @Column(name = "corrective_action", columnDefinition = "TEXT")
    private String correctiveAction;

    @Column(name = "status", length = 50)
    private String status;
}
