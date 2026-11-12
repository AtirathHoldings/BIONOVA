package com.bionova.entity.inventory;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_weighbridge")
@Getter
@Setter
public class InventoryWeighbridge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "slip_no", length = 50)
    private String slipNo;

    @Column(name = "vehicle_no", length = 50)
    private String vehicleNo;

    @Column(name = "transporter_name", length = 100)
    private String transporterName;

    @Column(name = "driver_name", length = 100)
    private String driverName;

    @Column(name = "material_type", length = 100)
    private String materialType;

    @Column(name = "gross_weight")
    private Double grossWeight;

    @Column(name = "tare_weight")
    private Double tareWeight;

    @Column(name = "net_weight")
    private Double netWeight;

    @Column(name = "uom", length = 20)
    private String uom;

    @Column(name = "weighbridge_operator", length = 100)
    private String weighbridgeOperator;

    @Column(name = "time_in", length = 30)
    private String timeIn;

    @Column(name = "time_out", length = 30)
    private String timeOut;

    @Column(name = "status", length = 50)
    private String status;
}

