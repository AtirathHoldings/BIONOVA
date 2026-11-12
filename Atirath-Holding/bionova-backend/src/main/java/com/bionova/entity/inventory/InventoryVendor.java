package com.bionova.entity.inventory;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_vendors")
@Getter
@Setter
public class InventoryVendor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "vendor_code", length = 50)
    private String vendorCode;

    @Column(name = "vendor_name", nullable = false, length = 150)
    private String vendorName;

    @Column(name = "tier", length = 30)
    private String tier;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;

    @Column(name = "contact_person", length = 100)
    private String contactPerson;

    @Column(name = "phone", length = 50)
    private String phone;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "gstin", length = 30)
    private String gstin;

    @Column(name = "pan", length = 30)
    private String pan;

    @Column(name = "msme_status", length = 100)
    private String msmeStatus;

    @Column(name = "rating")
    private Double rating;

    @Column(name = "payment_terms", length = 100)
    private String paymentTerms;

    @Column(name = "sla_status", length = 100)
    private String slaStatus;

    @Column(name = "contract_value", length = 50)
    private String contractValue;
}

