package com.bionova.entity.harvesting;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "harvest_batches")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class HarvestBatch {

    @Id
    @Column(name = "id", length = 50)
    private String id;

    @Column(name = "parcel_id", length = 50)
    private String parcelId;

    @Column(name = "farm_name", length = 150)
    private String farmName;

    @Column(name = "crop", length = 100)
    private String crop;

    @Column(name = "acreage", length = 50)
    private String acreage;

    @Column(name = "cut_number", length = 50)
    private String cutNumber;

    @Column(name = "planned_harvest_date", length = 50)
    private String plannedHarvestDate;

    @Column(name = "estimated_yield_mt")
    private Double estimatedYieldMT;

    @Column(name = "actual_harvested_mt")
    private Double actualHarvestedMT;

    @Column(name = "moisture_percent")
    private Double moisturePercent;

    @Column(name = "target_moisture", length = 50)
    private String targetMoisture;

    @Column(name = "assigned_fleet", length = 150)
    private String assignedFleet;

    @Column(name = "silage_bunker", length = 150)
    private String silageBunker;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "supervisor", length = 150)
    private String supervisor;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;
}
