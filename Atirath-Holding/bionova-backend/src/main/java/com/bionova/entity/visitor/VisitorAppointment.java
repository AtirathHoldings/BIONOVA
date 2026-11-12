package com.bionova.entity.visitor;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "visitor_appointments")
@Getter
@Setter
public class VisitorAppointment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "apt_code", length = 50)
    private String aptCode;

    @Column(name = "visitor_name", nullable = false, length = 150)
    private String visitorName;

    @Column(name = "organization", length = 150)
    private String organization;

    @Column(name = "phone", length = 50)
    private String phone;

    @Column(name = "host_employee", length = 150)
    private String hostEmployee;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;

    @Column(name = "scheduled_date", length = 30)
    private String scheduledDate;

    @Column(name = "scheduled_time", length = 50)
    private String scheduledTime;

    @Column(name = "venue", length = 100)
    private String venue;

    @Column(name = "type", length = 100)
    private String type;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "send_notification")
    private Boolean sendNotification;

    @Column(name = "remarks", length = 255)
    private String remarks;
}
