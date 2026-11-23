package com.bionova.entity.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_piping")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class InventoryPiping {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tag_no", length = 50)
    private String tagNo;

    @Column(name = "component_name", nullable = false, length = 150)
    private String componentName;

    @JsonProperty("name")
    public void setName(String name) {
        if (name != null) this.componentName = name;
    }
    @JsonProperty("name")
    public String getName() {
        return this.componentName;
    }

    @Column(name = "pnd_ref", length = 50)
    private String pndRef;

    @Column(name = "line_size", length = 50)
    private String lineSize;

    @Column(name = "pressure_rating", length = 50)
    private String pressureRating;

    @Column(name = "material_moc", length = 50)
    private String materialMoc;

    @Column(name = "stock_qty")
    private Integer stockQty;

    @JsonProperty("currentStock")
    public void setCurrentStock(Integer stock) {
        if (stock != null) this.stockQty = stock;
    }
    @JsonProperty("currentStock")
    public Integer getCurrentStock() {
        return this.stockQty;
    }

    @Column(name = "reorder_point")
    private Integer reorderPoint;

    @JsonProperty("reorderThreshold")
    public void setReorderThreshold(Integer threshold) {
        if (threshold != null) this.reorderPoint = threshold;
    }
    @JsonProperty("reorderThreshold")
    public Integer getReorderThreshold() {
        return this.reorderPoint;
    }

    @Column(name = "valve_type", length = 50)
    private String valveType;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;
}
