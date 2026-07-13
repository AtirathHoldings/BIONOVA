package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserDashboardResponseDto {
    private String fullName;
    private String role;
    private String department;
    private String photoUrl;

    // Summary Metric Cards
    private int myProjectsCount;
    private int myTasksCount;
    private int dueTodayCount;
    private int overdueTasksCount;
    private int completedTasksCount;

    // Metric Cards with Weekly Trends & Changes
    private MetricCardDto assignedTasksCard;
    private MetricCardDto openTasksCard;
    private MetricCardDto inProgressCard;
    private MetricCardDto overdueTasksCard;
    private MetricCardDto completedTasksCard;
    private MetricCardDto myProjectsCard;

    // Left Panel: To-Do List
    private List<TodoTaskDto> todoList;

    // Right Panel: Upcoming Tasks
    private List<UpcomingTaskDto> upcomingTasks;

    // Bottom Left: My Projects list
    private List<UserProjectDto> myProjects;

    // Bottom Right: Task Completion Status Distribution for Donut Chart
    private Map<String, Integer> taskStatusCounts;
    private double overallCompletionPercentage;

    // Performance Metrics
    private PerformanceMetricDto productivity;
    private PerformanceMetricDto taskCompletion;
    private PerformanceMetricDto qualityScore;

    // Recent Activity Feed
    private List<RecentActivityDto> recentActivity;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class MetricCardDto {
        private int currentCount;
        private int weeklyChange;
        private List<Integer> trend;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class PerformanceMetricDto {
        private int score;
        private String rating;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class RecentActivityDto {
        private Long logId;
        private String entityTyp;
        private Long entityId;
        private String statusFrom;
        private String statusTo;
        private String logDt; // String representation of datetime
        private String message;
        private String projectName;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class EmployeeAvatarDto {
        private Long empId;
        private String fullName;
        private String photoUrl;
        private String role;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class TodoTaskDto {
        private Long taskId;
        private String taskName;
        private String projectCodeName; // E.g., "PRJ-001 • Excavation Work"
        private String priority;        // High, Medium, Low
        private LocalDate dueDate;
        private String status;
        private boolean isOverdue;
        private boolean isDueToday;
        private String badge;
        private List<EmployeeAvatarDto> employees;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class UpcomingTaskDto {
        private Long taskId;
        private String taskName;
        private String projectCode; // E.g., "PRJ-001"
        private LocalDate startDate;
        private LocalDate dueDate;
        private Integer durationDays;
        private String priority;
        private List<EmployeeAvatarDto> employees;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class UserProjectDto {
        private Long projectId;
        private String projectName;
        private String projectCode;
        private String clientName;     // E.g., "Atirath Bio Energy Pvt. Ltd."
        private String plantName;      // E.g., "Nalgonda Plant"
        private String location;       // E.g., "Nalgonda Plant"
        private String role;           // E.g., "Site Engineer"
        private double progress;       // Percentage, e.g. 65.0
        private int tasksAssigned;
        private int openTasks;
        private String status;         // E.g., "In Progress"
        private String logo;           // Logo URL / base64 or path
        private LocalDate dueDate;     // Project End Date

        // Lead / On Time / Lag fields
        private String leadLagStatus;  // "LEAD", "ON_TIME", "LAG"
        private String leadLagLabel;   // "Lead", "On Time", "Lag"
        private String leadLagColor;   // hex color for badge
        private int    daysVariance;   // days ahead (LEAD) or behind (LAG)
    }
}
