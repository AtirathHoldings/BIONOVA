package com.bionova.entity.inventory;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_warranty")
@Getter
@Setter
public class InventoryWarranty {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tag_code", length = 50)
    private String tagCode;

    @Column(name = "equipment_name", nullable = false, length = 150)
    private String equipmentName;

    @Column(name = "oem_vendor", length = 100)
    private String oemVendor;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;

    @Column(name = "commissioning_date", length = 30)
    private String commissioningDate;

    @Column(name = "warranty_expires_on", length = 30)
    private String warrantyExpiresOn;

    @Column(name = "amc_active")
    private Boolean amcActive;

    @Column(name = "amc_vendor", length = 100)
    private String amcVendor;

    @Column(name = "claim_history", length = 255)
    private String claimHistory;

    @Column(name = "status", length = 50)
    private String status;
}

