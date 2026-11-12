package com.bionova.entity.visitor;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "visitor_material_inward")
@Getter
@Setter
public class VisitorMaterialInward {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "inward_code", length = 50)
    private String inwardCode;

    @Column(name = "date", length = 30)
    private String date;

    @Column(name = "time", length = 30)
    private String time;

    @Column(name = "item_description", nullable = false, length = 255)
    private String itemDescription;

    @Column(name = "quantity", length = 50)
    private String quantity;

    @Column(name = "po_challan_no", length = 50)
    private String poChallanNo;

    @Column(name = "vendor_name", length = 150)
    private String vendorName;

    @Column(name = "delivery_carrier", length = 100)
    private String deliveryCarrier;

    @Column(name = "receiving_department", length = 100)
    private String receivingDepartment;

    @Column(name = "type", length = 50)
    private String type;

    @Column(name = "inspector_name", length = 100)
    private String inspectorName;

    @Column(name = "status", length = 50)
    private String status;
}

