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

    @Column(name = "tag_no", length = 100)
    private String tagNo;

    @JsonProperty("sku")
    public void setSku(String sku) {
        if (sku != null) this.tagNo = sku;
    }
    @JsonProperty("sku")
    public String getSku() {
        return this.tagNo;
    }

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

    @JsonProperty("category")
    public void setCategory(String category) {
        if (category != null) this.valveType = category;
    }

    @JsonProperty("category")
    public String getCategory() {
        return this.valveType != null ? this.valveType : "Manual Valves";
    }

    @Column(name = "plant_location", length = 100)
    private String plantLocation;

    @JsonProperty("location")
    public void setLocation(String loc) {
        if (loc != null) this.plantLocation = loc;
    }

    @JsonProperty("location")
    public String getLocation() {
        return this.plantLocation != null ? this.plantLocation : "Instrument Store Room";
    }

    @JsonProperty("material")
    public void setMaterial(String material) {
        if (material != null) this.materialMoc = material;
    }

    @JsonProperty("material")
    public String getMaterial() {
        return this.materialMoc != null ? this.materialMoc : "";
    }

    @JsonProperty("sizeRating")
    public void setSizeRating(String sizeRating) {
        if (sizeRating != null) this.pressureRating = sizeRating;
    }

    @JsonProperty("sizeRating")
    public String getSizeRating() {
        return this.pressureRating != null ? this.pressureRating : "";
    }

    @JsonProperty("pidLineRef")
    public void setPidLineRef(String pidLineRef) {
        if (pidLineRef != null) this.pndRef = pidLineRef;
    }

    @JsonProperty("pidLineRef")
    public String getPidLineRef() {
        return this.pndRef != null ? this.pndRef : "";
    }

    @Transient
    private String uom;

    @JsonProperty("uom")
    public void setUom(String uom) {
        this.uom = uom;
    }

    @JsonProperty("uom")
    public String getUom() {
        return this.uom != null ? this.uom : "Units";
    }
}
