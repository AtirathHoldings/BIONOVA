package com.bionova.entity.procurement;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "purchase_requisitions")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class PurchaseRequisition {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pr_number", length = 50)
    private String prNumber;

    @Column(name = "department", length = 100)
    private String department;

    @Column(name = "plant_facility", length = 100)
    private String plantFacility;

    @Column(name = "priority", length = 50)
    private String priority;

    @Column(name = "required_date", length = 50)
    private String requiredDate;

    @Column(name = "justification", columnDefinition = "TEXT")
    private String justification;

    @Column(name = "status", length = 50)
    private String status;

    @Column(name = "est_total_cost")
    private Double estTotalCost;

    @Column(name = "requested_by", length = 100)
    private String requestedBy;

    @Column(name = "approved_by", length = 100)
    private String approvedBy;

    @Column(name = "items", columnDefinition = "TEXT")
    private String items;

    @JsonProperty("items")
    public void setItemsFromJson(JsonNode node) {
        if (node != null && !node.isNull()) {
            this.items = node.isTextual() ? node.asText() : node.toString();
        } else {
            this.items = null;
        }
    }

    @JsonProperty("items")
    public Object getItemsAsJson() {
        if (this.items == null || this.items.trim().isEmpty()) return null;
        try {
            return MAPPER.readTree(this.items);
        } catch (Exception e) {
            return this.items;
        }
    }
}
