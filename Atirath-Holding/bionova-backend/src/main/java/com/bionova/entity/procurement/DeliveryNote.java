package com.bionova.entity.procurement;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "delivery_notes")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class DeliveryNote {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "grn_number", length = 50)
    private String grnNumber;

    @Column(name = "po_number", length = 50)
    private String poNumber;

    @Column(name = "supplier_name", length = 150)
    private String supplierName;

    @Column(name = "transporter", length = 150)
    private String transporter;

    @Column(name = "vehicle_no", length = 50)
    private String vehicleNo;

    @Column(name = "e_way_bill", length = 100)
    private String eWayBill;

    @Column(name = "received_date", length = 50)
    private String receivedDate;

    @Column(name = "receiving_zone", length = 150)
    private String receivingZone;

    @Column(name = "ordered_qty")
    private Double orderedQty;

    @Column(name = "dispatched_qty")
    private Double dispatchedQty;

    @Column(name = "received_qty")
    private Double receivedQty;

    @Column(name = "accepted_qty")
    private Double acceptedQty;

    @Column(name = "rejected_qty")
    private Double rejectedQty;

    @Column(name = "inspection_status", length = 100)
    private String inspectionStatus;

    @Column(name = "remarks", columnDefinition = "TEXT")
    private String remarks;
}
