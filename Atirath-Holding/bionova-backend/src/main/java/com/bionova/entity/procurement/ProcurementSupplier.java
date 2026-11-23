package com.bionova.entity.procurement;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "procurement_suppliers")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class ProcurementSupplier {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "supplier_code", length = 50)
    private String supplierCode;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "tier", length = 100)
    private String tier;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "contact_person", length = 100)
    private String contactPerson;

    @Column(name = "phone", length = 50)
    private String phone;

    @Column(name = "email", length = 100)
    private String email;

    @Column(name = "plant_facility", length = 100)
    private String plantFacility;

    @Column(name = "gstin", length = 50)
    private String gstin;

    @Column(name = "pan_no", length = 50)
    private String panNo;

    @Column(name = "msme_type", length = 50)
    private String msmeType;

    @Column(name = "rating")
    private Double rating;

    @Column(name = "active_pos_count")
    private Integer activePosCount;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "payment_terms", length = 100)
    private String paymentTerms;

    @Column(name = "address", columnDefinition = "TEXT")
    private String address;
}
