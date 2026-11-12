package com.bionova.entity.visitor;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "visitor_material_outward")
@Getter
@Setter
public class VisitorMaterialOutward {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "outward_code", length = 50)
    private String outwardCode;

    @Column(name = "date", length = 30)
    private String date;

    @Column(name = "time", length = 30)
    private String time;

    @Column(name = "item_description", nullable = false, length = 255)
    private String itemDescription;

    @Column(name = "quantity", length = 50)
    private String quantity;

    @Column(name = "dispatch_challan_no", length = 50)
    private String dispatchChallanNo;

    @Column(name = "recipient", length = 150)
    private String recipient;

    @Column(name = "vehicle_no", length = 50)
    private String vehicleNo;

    @Column(name = "type", length = 50)
    private String type;

    @Column(name = "authorized_by", length = 100)
    private String authorizedBy;

    @Column(name = "gate_sign_off_time", length = 30)
    private String gateSignOffTime;

    @Column(name = "status", length = 50)
    private String status;
}
