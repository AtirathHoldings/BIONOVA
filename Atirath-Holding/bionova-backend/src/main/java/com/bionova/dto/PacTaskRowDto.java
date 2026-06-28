package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PacTaskRowDto {
    private String milestoneName;
    private Long taskId;
    private String taskCode;
    private String taskName;
    private PacEmployeeDto assignee;
    private PacEmployeeDto reviewer;
    private PacEmployeeDto approver;
    private PacEmployeeDto manager;
    private Boolean processExists;
    private List<String> permissionSummary;
    private String assignedOn;
}
