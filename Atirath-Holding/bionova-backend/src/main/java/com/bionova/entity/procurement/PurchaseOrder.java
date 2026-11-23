package com.bionova.entity.procurement;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "purchase_orders")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class PurchaseOrder {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "po_number", length = 50)
    private String poNumber;

    @Column(name = "supplier_name", length = 150)
    private String supplierName;

    @Column(name = "supplier_id")
    private Long supplierId;

    @Column(name = "plant_facility", length = 100)
    private String plantFacility;

    @Column(name = "order_date", length = 50)
    private String orderDate;

    @Column(name = "delivery_date", length = 50)
    private String deliveryDate;

    @Column(name = "payment_terms", length = 100)
    private String paymentTerms;

    @Column(name = "delivery_terms", length = 150)
    private String deliveryTerms;

    @Column(name = "shipping_address", columnDefinition = "TEXT")
    private String shippingAddress;

    @Column(name = "subtotal")
    private Double subtotal;

    @Column(name = "tax_amount")
    private Double taxAmount;

    @Column(name = "total_amount")
    private Double totalAmount;

    @Column(name = "status", length = 50)
    private String status;

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
