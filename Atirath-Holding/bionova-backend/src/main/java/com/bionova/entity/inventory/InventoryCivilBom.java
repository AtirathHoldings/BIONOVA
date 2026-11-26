package com.bionova.entity.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_civil_bom")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class InventoryCivilBom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "spec_code", length = 100)
    private String specCode;

    @JsonProperty("code")
    public void setCode(String code) {
        if (code != null) this.specCode = code;
    }
    @JsonProperty("code")
    public String getCode() {
        return this.specCode;
    }

    @JsonProperty("sku")
    public void setSku(String sku) {
        if (sku != null) this.specCode = sku;
    }
    @JsonProperty("sku")
    public String getSku() {
        return this.specCode;
    }

    @Column(name = "material_name", nullable = false, length = 150)
    private String materialName;

    @JsonProperty("name")
    public void setName(String name) {
        if (name != null) this.materialName = name;
    }
    @JsonProperty("name")
    public String getName() {
        return this.materialName;
    }

    @Column(name = "stage", length = 100)
    private String stage;

    @JsonProperty("category")
    public void setCategory(String category) {
        if (category != null) this.stage = category;
    }
    @JsonProperty("category")
    public String getCategory() {
        return this.stage;
    }

    @Column(name = "planned_qty")
    private Double plannedQty;

    @JsonProperty("bomRequiredQty")
    public void setBomRequiredQty(Double qty) {
        if (qty != null) this.plannedQty = qty;
    }
    @JsonProperty("bomRequiredQty")
    public Double getBomRequiredQty() {
        return this.plannedQty;
    }

    @Column(name = "issued_qty")
    private Double issuedQty;

    @JsonProperty("allocatedQty")
    public void setAllocatedQty(Double qty) {
        if (qty != null) this.issuedQty = qty;
    }
    @JsonProperty("allocatedQty")
    public Double getAllocatedQty() {
        return this.issuedQty;
    }

    @Column(name = "uom", length = 20)
    private String uom;

    @Column(name = "supplier", length = 150)
    private String supplier;

    @Column(name = "delivery_status", length = 50)
    private String deliveryStatus;

    @JsonProperty("status")
    public void setStatus(String status) {
        if (status != null) this.deliveryStatus = status;
    }
    @JsonProperty("status")
    public String getStatus() {
        return this.deliveryStatus;
    }

    @Column(name = "cost_per_unit")
    private Double costPerUnit;

    @JsonProperty("unitCost")
    public void setUnitCost(Double cost) {
        if (cost != null) this.costPerUnit = cost;
    }
    @JsonProperty("unitCost")
    public Double getUnitCost() {
        return this.costPerUnit;
    }

    @Column(name = "inspection_status", length = 50)
    private String inspectionStatus;

    @Transient
    private String gradeSpec;

    @JsonProperty("gradeSpec")
    public void setGradeSpec(String gradeSpec) {
        this.gradeSpec = gradeSpec;
    }

    @JsonProperty("gradeSpec")
    public String getGradeSpec() {
        return this.gradeSpec != null ? this.gradeSpec : "";
    }

    @Transient
    private Double currentStock;

    @JsonProperty("currentStock")
    public void setCurrentStock(Double currentStock) {
        this.currentStock = currentStock;
    }

    @JsonProperty("currentStock")
    public Double getCurrentStock() {
        if (this.currentStock != null) return this.currentStock;
        double p = this.plannedQty != null ? this.plannedQty : 0;
        double i = this.issuedQty != null ? this.issuedQty : 0;
        return Math.max(0, p - i);
    }

    @Transient
    private Double procuredQty;

    @JsonProperty("procuredQty")
    public void setProcuredQty(Double procuredQty) {
        this.procuredQty = procuredQty;
    }

    @JsonProperty("procuredQty")
    public Double getProcuredQty() {
        return this.procuredQty != null ? this.procuredQty : (this.plannedQty != null ? this.plannedQty : 0.0);
    }

    @Transient
    private String allocatedStructure;

    @JsonProperty("allocatedStructure")
    public void setAllocatedStructure(String allocatedStructure) {
        this.allocatedStructure = allocatedStructure;
    }

    @JsonProperty("allocatedStructure")
    public String getAllocatedStructure() {
        return this.allocatedStructure != null ? this.allocatedStructure : (this.stage != null ? this.stage : "");
    }
}
