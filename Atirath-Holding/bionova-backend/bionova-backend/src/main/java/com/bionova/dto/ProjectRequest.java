package com.bionova.dto;

import lombok.Data;

@Data
public class ProjectRequest {

    private String projectName;
    private String projectDescription;
    private Long deptId;
    private String priority;

    private String tentativeStartDate;
    private String tentativeEndDate;

    private Long companyId;
    private Long plantId;

    private String projectObjective;
    private String expectedDeliverables;
}