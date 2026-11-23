package com.bionova.entity.dpr;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "dpr_records")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class DprRecord {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Id
    @Column(name = "id", length = 50)
    private String id;

    @Column(name = "date", length = 50)
    private String date;

    @Column(name = "shift", length = 100)
    private String shift;

    @Column(name = "project_name", length = 150)
    private String projectName;

    @Column(name = "contractor", length = 150)
    private String contractor;

    @Column(name = "engineer", length = 150)
    private String engineer;

    @Column(name = "weather", length = 100)
    private String weather;

    @Column(name = "workable_day")
    private Boolean workableDay;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "submitted_at", length = 50)
    private String submittedAt;

    @Column(name = "approved_by", length = 100)
    private String approvedBy;

    @Column(name = "approved_at", length = 50)
    private String approvedAt;

    @Column(name = "pm_remarks", columnDefinition = "TEXT")
    private String pmRemarks;

    @Column(name = "tomorrow_plan", columnDefinition = "TEXT")
    private String tomorrowPlan;

    @Column(name = "activities", columnDefinition = "TEXT")
    private String activities;

    @JsonProperty("activities")
    public void setActivitiesFromJson(JsonNode node) {
        this.activities = (node != null && !node.isNull()) ? (node.isTextual() ? node.asText() : node.toString()) : null;
    }

    @JsonProperty("activities")
    public Object getActivitiesAsJson() {
        if (this.activities == null || this.activities.trim().isEmpty()) return null;
        try { return MAPPER.readTree(this.activities); } catch (Exception e) { return this.activities; }
    }

    @Column(name = "manpower", columnDefinition = "TEXT")
    private String manpower;

    @JsonProperty("manpower")
    public void setManpowerFromJson(JsonNode node) {
        this.manpower = (node != null && !node.isNull()) ? (node.isTextual() ? node.asText() : node.toString()) : null;
    }

    @JsonProperty("manpower")
    public Object getManpowerAsJson() {
        if (this.manpower == null || this.manpower.trim().isEmpty()) return null;
        try { return MAPPER.readTree(this.manpower); } catch (Exception e) { return this.manpower; }
    }

    @Column(name = "equipment", columnDefinition = "TEXT")
    private String equipment;

    @JsonProperty("equipment")
    public void setEquipmentFromJson(JsonNode node) {
        this.equipment = (node != null && !node.isNull()) ? (node.isTextual() ? node.asText() : node.toString()) : null;
    }

    @JsonProperty("equipment")
    public Object getEquipmentAsJson() {
        if (this.equipment == null || this.equipment.trim().isEmpty()) return null;
        try { return MAPPER.readTree(this.equipment); } catch (Exception e) { return this.equipment; }
    }

    @Column(name = "materials", columnDefinition = "TEXT")
    private String materials;

    @JsonProperty("materials")
    public void setMaterialsFromJson(JsonNode node) {
        this.materials = (node != null && !node.isNull()) ? (node.isTextual() ? node.asText() : node.toString()) : null;
    }

    @JsonProperty("materials")
    public Object getMaterialsAsJson() {
        if (this.materials == null || this.materials.trim().isEmpty()) return null;
        try { return MAPPER.readTree(this.materials); } catch (Exception e) { return this.materials; }
    }

    @Column(name = "hse", columnDefinition = "TEXT")
    private String hse;

    @JsonProperty("hse")
    public void setHseFromJson(JsonNode node) {
        this.hse = (node != null && !node.isNull()) ? (node.isTextual() ? node.asText() : node.toString()) : null;
    }

    @JsonProperty("hse")
    public Object getHseAsJson() {
        if (this.hse == null || this.hse.trim().isEmpty()) return null;
        try { return MAPPER.readTree(this.hse); } catch (Exception e) { return this.hse; }
    }

    @Column(name = "photos", columnDefinition = "TEXT")
    private String photos;

    @JsonProperty("photos")
    public void setPhotosFromJson(JsonNode node) {
        this.photos = (node != null && !node.isNull()) ? (node.isTextual() ? node.asText() : node.toString()) : null;
    }

    @JsonProperty("photos")
    public Object getPhotosAsJson() {
        if (this.photos == null || this.photos.trim().isEmpty()) return null;
        try { return MAPPER.readTree(this.photos); } catch (Exception e) { return this.photos; }
    }

    @Column(name = "audit_trail", columnDefinition = "TEXT")
    private String auditTrail;

    @JsonProperty("auditTrail")
    public void setAuditTrailFromJson(JsonNode node) {
        this.auditTrail = (node != null && !node.isNull()) ? (node.isTextual() ? node.asText() : node.toString()) : null;
    }

    @JsonProperty("auditTrail")
    public Object getAuditTrailAsJson() {
        if (this.auditTrail == null || this.auditTrail.trim().isEmpty()) return null;
        try { return MAPPER.readTree(this.auditTrail); } catch (Exception e) { return this.auditTrail; }
    }
}
