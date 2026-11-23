package com.bionova.entity.dispatchlogistics;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "logistics_weighbridge_slips")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class LogisticsWeighbridgeSlip {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "slip_number", length = 50)
    private String slipNumber;

    @Column(name = "trip_number", length = 50)
    private String tripNumber;

    @Column(name = "vehicle_no", length = 50)
    private String vehicleNo;

    @Column(name = "inbound_gross_mt")
    private Double inboundGrossMT;

    @Column(name = "outbound_tare_mt")
    private Double outboundTareMT;

    @Column(name = "net_weight_mt")
    private Double netWeightMT;

    @Column(name = "expected_qty_mt")
    private Double expectedQtyMT;

    @Column(name = "operator_name", length = 150)
    private String operatorName;

    @Column(name = "scale_timestamp", length = 50)
    private String scaleTimestamp;

    @Column(name = "status", length = 50)
    private String status;
}
