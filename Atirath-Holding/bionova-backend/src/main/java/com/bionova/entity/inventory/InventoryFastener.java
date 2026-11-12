package com.bionova.entity.inventory;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_fasteners")
@Getter
@Setter
public class InventoryFastener {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "item_code", length = 50)
    private String itemCode;

    @Column(name = "description", nullable = false, length = 150)
    private String description;

    @Column(name = "grade", length = 50)
    private String grade;

    @Column(name = "size", length = 50)
    private String size;

    @Column(name = "in_stock")
    private Integer inStock;

    @Column(name = "reorder_level")
    private Integer reorderLevel;

    @Column(name = "uom", length = 20)
    private String uom;

    @Column(name = "bin_location", length = 50)
    private String binLocation;

    @Column(name = "supplier", length = 100)
    private String supplier;

    @Column(name = "standard_cert", length = 100)
    private String standardCert;
}

