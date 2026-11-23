package com.bionova.entity.dispatchlogistics;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "fleet_drivers")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class FleetDriver {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", length = 150)
    private String name;

    @Column(name = "phone", length = 50)
    private String phone;

    @Column(name = "license_number", length = 50)
    private String licenseNumber;

    @Column(name = "license_expiry", length = 50)
    private String licenseExpiry;

    @Column(name = "hazmat_certified")
    private Boolean hazmatCertified;

    @Column(name = "assigned_vehicle", length = 100)
    private String assignedVehicle;

    @Column(name = "duty_status", length = 50)
    private String dutyStatus;
}
