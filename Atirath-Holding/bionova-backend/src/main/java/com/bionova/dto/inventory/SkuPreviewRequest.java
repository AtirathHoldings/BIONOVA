package com.bionova.dto.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class SkuPreviewRequest {
    /**
     * Category: AGRI, CIVIL_BOM, FASTENERS, PIPING, INSTRUMENTATION
     */
    private String category;

    // Agri specific
    private String itemType;
    private String grade;
    private String packSize;

    // Civil BOM specific
    private String discipline;
    private String item;
    private String specification;

    // Fasteners specific
    private String fastenerType;
    private String material;
    private String diameter;
    private String length;
    private String fastenerGrade;

    // Piping & Instrumentation specific
    private String pipingType;
    private String pipingMaterial;
    private String pipingSize;
    private String pressureClass;

    // Instrumentation specific
    private String instrumentType;
    private String range;
    private String connection;
}
