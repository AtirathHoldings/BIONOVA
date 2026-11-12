package com.bionova.entity.inventory;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "inventory_piping")
@Getter
@Setter
public class InventoryPiping {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tag_no", length = 50)
    private String tagNo;

    @Column(name = "component_name", nullable = false, length = 150)
    private String componentName;

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

    @Column(name = "reorder_point")
    private Integer reorderPoint;

    @Column(name = "valve_type", length = 50)
    private String valveType;

    @Column(name = "plant_location", length = 100)
    private String plantLocation;
}

