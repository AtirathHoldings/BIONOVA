package com.bionova.entity.visitor;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "visitor_requests")
@Getter
@Setter
public class VisitorRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "req_code", length = 50)
    private String reqCode;

    @Column(name = "requester_name", nullable = false, length = 150)
    private String requesterName;

    @Column(name = "organization", length = 150)
    private String organization;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "phone", length = 50)
    private String phone;

    @Column(name = "visitor_category", length = 50)
    private String visitorCategory;

    @Column(name = "host_name", length = 150)
    private String hostName;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;

    @Column(name = "requested_date", length = 30)
    private String requestedDate;

    @Column(name = "requested_time", length = 30)
    private String requestedTime;

    @Column(name = "purpose", length = 255)
    private String purpose;

    @Column(name = "visitor_count")
    private Integer visitorCount;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "submitted_at", length = 50)
    private String submittedAt;

    @Column(name = "rejection_reason", length = 255)
    private String rejectionReason;
}
