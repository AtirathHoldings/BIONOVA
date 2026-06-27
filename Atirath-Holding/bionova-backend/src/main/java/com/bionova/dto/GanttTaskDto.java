package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class GanttTaskDto {
    private String id;           // Unique ID across all types, e.g., "PRJ-1", "MS-2", "TSK-3"
    private String name;         // Display name
    private String type;         // "project", "milestone", "task"
    private LocalDate startDate;
    private LocalDate endDate;
    private Double progress;     // Progress percentage as 0.0 to 1.0
    private String parent;       // Parent ID (null for project, "PRJ-x" for milestone, "MS-y" for task)
    private String status;       // Raw status string
    private String code;         // Code, e.g., "PRJ-001", "MS-01", "TSK-05"
    private String assignee;     // Assigned employee's full name (null for project/milestone)
    private String dependencies; // Predecessor/Dependency task or milestone ID
    private LocalDate plannedStartDate; // Baseline/Original plan start date
    private LocalDate plannedEndDate;   // Baseline/Original plan end date
}
