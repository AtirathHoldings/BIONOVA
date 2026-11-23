package com.bionova.entity.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_fasteners")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class InventoryFastener {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "item_code", length = 50)
    private String itemCode;

    @JsonProperty("sku")
    public void setSku(String sku) {
        if (sku != null) this.itemCode = sku;
    }
    @JsonProperty("sku")
    public String getSku() {
        return this.itemCode;
    }

    @Column(name = "description", nullable = false, length = 150)
    private String description;

    @JsonProperty("name")
    public void setName(String name) {
        if (name != null) this.description = name;
    }
    @JsonProperty("name")
    public String getName() {
        return this.description;
    }

    @Column(name = "grade", length = 50)
    private String grade;

    @Column(name = "size", length = 50)
    private String size;

    @Column(name = "in_stock")
    private Integer inStock;

    @JsonProperty("currentStock")
    public void setCurrentStock(Integer stock) {
        if (stock != null) this.inStock = stock;
    }
    @JsonProperty("currentStock")
    public Integer getCurrentStock() {
        return this.inStock;
    }

    @Column(name = "reorder_level")
    private Integer reorderLevel;

    @JsonProperty("reorderThreshold")
    public void setReorderThreshold(Integer threshold) {
        if (threshold != null) this.reorderLevel = threshold;
    }
    @JsonProperty("reorderThreshold")
    public Integer getReorderThreshold() {
        return this.reorderLevel;
    }

    @Column(name = "uom", length = 20)
    private String uom;

    @Column(name = "bin_location", length = 50)
    private String binLocation;

    @Column(name = "supplier", length = 100)
    private String supplier;

    @Column(name = "standard_cert", length = 100)
    private String standardCert;
}
