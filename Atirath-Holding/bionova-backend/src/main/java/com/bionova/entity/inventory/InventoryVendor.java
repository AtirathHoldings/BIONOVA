package com.bionova.entity.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_vendors")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class InventoryVendor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "vendor_code", length = 50)
    private String vendorCode;

    @JsonProperty("code")
    public void setCode(String code) {
        if (code != null) this.vendorCode = code;
    }
    @JsonProperty("code")
    public String getCode() {
        return this.vendorCode;
    }

    @Column(name = "vendor_name", nullable = false, length = 150)
    private String vendorName;

    @JsonProperty("name")
    public void setName(String name) {
        if (name != null) this.vendorName = name;
    }
    @JsonProperty("name")
    public String getName() {
        return this.vendorName;
    }

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
}
