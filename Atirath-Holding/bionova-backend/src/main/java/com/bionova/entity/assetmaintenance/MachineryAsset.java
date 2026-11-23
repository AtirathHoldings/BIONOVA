package com.bionova.entity.assetmaintenance;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "machinery_assets")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class MachineryAsset {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "asset_code", length = 50)
    private String assetCode;

    @Column(name = "name", length = 150)
    private String name;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "facility", length = 100)
    private String facility;

    @Column(name = "oem_manufacturer", length = 150)
    private String oemManufacturer;

    @Column(name = "model_serial", length = 100)
    private String modelSerial;

    @Column(name = "commission_date", length = 50)
    private String commissionDate;

    @Column(name = "criticality", length = 50)
    private String criticality;

    @Column(name = "operating_status", length = 50)
    private String operatingStatus;
}
