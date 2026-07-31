package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProjectAccessControlResponseDto {
    private Long projectId;
    private String projectCode;
    private String projectName;
    private String companyName;
    private String projectManager;
    private Integer totalTasks;
    private Integer totalMilestones;
    private Integer totalEmployees;
    private String lastUpdated;
    private List<PacTaskRowDto> tasks;
}
