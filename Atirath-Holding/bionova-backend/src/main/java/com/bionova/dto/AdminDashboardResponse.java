package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminDashboardResponse {
    private long employeeCount;
    private long departmentCount;
    private long activeProjectsCount;
    private long criticalAlertsCount;
    private Map<String, Long> projectStatusOverview;
    private Map<String, Object> milestoneProgress;
    private Map<String, Object> taskOverview;
    private List<ActivityDto> systemActivities;
    private List<DeadlineDto> upcomingDeadlines;
    private List<ProjectProgressDto> topProjects;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ActivityDto {
        private String description;
        private String actor;
        private String timestamp;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DeadlineDto {
        private String title;
        private String projectName;
        private LocalDate dueDate;
        private String timeLeft;
        private boolean isCritical;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProjectProgressDto {
        private Long projectId;
        private String projectName;
        private String projectCode;
        private double progressPercent;
    }
}
