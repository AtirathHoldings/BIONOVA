package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExternalTaskUpdateDto {
    private String taskSts;       // OPEN, WIP, SUBMIT_REVIEW, CLOSED, etc.
    private String subStatus;     // Optional sub-status / comments
    private String remarks;       // Additional notes or deliverables summary
}
