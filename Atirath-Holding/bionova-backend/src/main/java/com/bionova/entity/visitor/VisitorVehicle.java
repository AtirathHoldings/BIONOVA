package com.bionova.entity.visitor;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "visitor_vehicles")
@Getter
@Setter
public class VisitorVehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "vehicle_no", nullable = false, length = 50)
    private String vehicleNo;

    @Column(name = "type", length = 100)
    private String type;

    @Column(name = "driver_name", nullable = false, length = 100)
    private String driverName;

    @Column(name = "phone", length = 50)
    private String phone;

    @Column(name = "license_no", length = 50)
    private String licenseNo;

    @Column(name = "purpose", length = 255)
    private String purpose;

    @Column(name = "consignment_weight", length = 50)
    private String consignmentWeight;

    @Column(name = "spark_arrestor_verified")
    private Boolean sparkArrestorVerified;

    @Column(name = "gate_in_time", length = 30)
    private String gateInTime;

    @Column(name = "gate_out_time", length = 30)
    private String gateOutTime;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "parking_bay", length = 50)
    private String parkingBay;

    @Column(name = "weighbridge_slip_no", length = 50)
    private String weighbridgeSlipNo;
}

