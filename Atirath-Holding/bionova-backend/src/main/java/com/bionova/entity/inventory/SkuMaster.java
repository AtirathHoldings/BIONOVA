package com.bionova.entity.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "inventory_sku_master", indexes = {
    @Index(name = "idx_sku_master_cat_type", columnList = "category, option_type")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class SkuMaster {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * Category: AGRI, CIVIL_BOM, FASTENERS, PIPING, INSTRUMENTATION
     */
    @Column(name = "category", nullable = false, length = 50)
    private String category;

    /**
     * Option Type: ITEM_TYPE, DISCIPLINE, GRADE, PACK_SIZE, MATERIAL,
     * DIAMETER, LENGTH, PRESSURE_CLASS, RANGE, CONNECTION_TYPE, FORMAT_RULE
     */
    @Column(name = "option_type", nullable = false, length = 50)
    private String optionType;

    /**
     * Short normalized code used in SKU: e.g. MZE, CIV, A1, 050, SS304, M12, 150, 010BAR, THD
     */
    @Column(name = "code", nullable = false, length = 50)
    private String code;

    /**
     * Human-readable display label: e.g. Maize Feedstock (MZE)
     */
    @Column(name = "label", nullable = false, length = 150)
    private String label;

    /**
     * Extra metadata or specifications (e.g. description, unit, default)
     */
    @Column(name = "metadata", length = 255)
    private String metadata;

    @Column(name = "sort_order")
    private Integer sortOrder;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;
}
