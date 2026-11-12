package com.bionova.entity.inventory;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_alerts")
@Getter
@Setter
public class InventoryAlert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "alert_type", length = 50)
    private String alertType;

    @Column(name = "item_ref", length = 50)
    private String itemRef;

    @Column(name = "description", nullable = false, length = 255)
    private String description;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;

    @Column(name = "severity", length = 30)
    private String severity;

    @Column(name = "expiry_days_remaining")
    private Integer expiryDaysRemaining;

    @Column(name = "action_taken", length = 100)
    private String actionTaken;

    @Column(name = "timestamp", length = 50)
    private String timestamp;
}

