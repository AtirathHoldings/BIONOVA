package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserDashboardResponseDto {
    private String fullName;
    private String role;
    private String department;

    // Summary Metric Cards
    private int myProjectsCount;
    private int myTasksCount;
    private int dueTodayCount;
    private int overdueTasksCount;
    private int completedTasksCount;

    // Left Panel: To-Do List
    private List<TodoTaskDto> todoList;

    // Right Panel: Upcoming Tasks
    private List<UpcomingTaskDto> upcomingTasks;

    // Bottom Left: My Projects list
    private List<UserProjectDto> myProjects;

    // Bottom Right: Task Completion Status Distribution for Donut Chart
    private Map<String, Integer> taskStatusCounts;
    private double overallCompletionPercentage;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class TodoTaskDto {
        private Long taskId;
        private String taskName;
        private String projectCodeName; // E.g., "PRJ-001 • Excavation Work"
        private String priority;        // High, Medium, Low
        private LocalDate dueDate;
        private boolean isOverdue;
        private boolean isDueToday;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class UpcomingTaskDto {
        private Long taskId;
        private String taskName;
        private String projectCode; // E.g., "PRJ-001"
        private LocalDate dueDate;
        private String priority;
    }

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class UserProjectDto {
        private Long projectId;
        private String projectName;
        private String projectCode;
        private String clientName; // E.g., "Atirath Bio Energy Pvt. Ltd."
        private String plantName;  // E.g., "Nalgonda Plant"
        private String role;       // E.g., "Site Engineer"
        private double progress;   // Percentage, e.g. 65.0
        private int tasksAssigned;
        private int openTasks;
        private String status;     // E.g., "In Progress"
    }
}
