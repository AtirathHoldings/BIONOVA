package com.bionova.dto.inventory;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class SkuPreviewResponse {
    private String sku;
    private String format;
    private String prefix;
    private String nextSerial;
    private boolean valid;
    private List<String> missingFields;
    private Map<String, String> specifications;
}
