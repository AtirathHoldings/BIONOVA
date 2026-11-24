package com.bionova.entity.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_items")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class InventoryItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "sku", length = 50)
    private String sku;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "category", length = 50)
    private String category;

    @Column(name = "batch_no", length = 50)
    private String batchNo;

    @Column(name = "current_stock")
    private Double currentStock;

    @Column(name = "reorder_threshold")
    private Double reorderThreshold;

    @Column(name = "uom", length = 20)
    private String uom;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;

    @Column(name = "unit_cost")
    private Double unitCost;

    @Column(name = "expiry_date", length = 30)
    private String expiryDate;

    @Column(name = "status", length = 30)
    private String status;

    @Column(name = "remarks", length = 255)
    private String remarks;

    @JsonProperty("notes")
    public void setNotes(String notes) {
        if (notes != null) this.remarks = notes;
    }

    @JsonProperty("notes")
    public String getNotes() {
        return this.remarks;
    }

    @Transient
    private String supplier;

    @JsonProperty("supplier")
    public void setSupplier(String supplier) {
        this.supplier = supplier;
    }

    @JsonProperty("supplier")
    public String getSupplier() {
        return this.supplier;
    }
}

