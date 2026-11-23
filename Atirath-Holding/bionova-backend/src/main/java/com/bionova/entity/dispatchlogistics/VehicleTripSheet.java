package com.bionova.entity.dispatchlogistics;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "vehicle_trip_sheets")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class VehicleTripSheet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "trip_number", length = 50)
    private String tripNumber;

    @Column(name = "origin", length = 150)
    private String origin;

    @Column(name = "destination", length = 150)
    private String destination;

    @Column(name = "assigned_vehicle", length = 100)
    private String assignedVehicle;

    @Column(name = "assigned_driver", length = 150)
    private String assignedDriver;

    @Column(name = "cargo_category", length = 100)
    private String cargoCategory;

    @Column(name = "dispatch_qty_mt")
    private Double dispatchQtyMT;

    @Column(name = "dispatch_date_time", length = 50)
    private String dispatchDateTime;

    @Column(name = "status", length = 50)
    private String status;
}
