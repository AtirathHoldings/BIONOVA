package com.bionova.entity.inventory;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_civil_bom")
@Getter
@Setter
public class InventoryCivilBom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "spec_code", length = 50)
    private String specCode;

    @Column(name = "material_name", nullable = false, length = 150)
    private String materialName;

    @Column(name = "stage", length = 100)
    private String stage;

    @Column(name = "planned_qty")
    private Double plannedQty;

    @Column(name = "issued_qty")
    private Double issuedQty;

    @Column(name = "uom", length = 20)
    private String uom;

    @Column(name = "supplier", length = 150)
    private String supplier;

    @Column(name = "delivery_status", length = 50)
    private String deliveryStatus;

    @Column(name = "cost_per_unit")
    private Double costPerUnit;

    @Column(name = "inspection_status", length = 50)
    private String inspectionStatus;
}

