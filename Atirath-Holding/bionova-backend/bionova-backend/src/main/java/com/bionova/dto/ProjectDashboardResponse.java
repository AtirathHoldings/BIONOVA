package com.bionova.dto;

import lombok.Getter;
import lombok.Setter;
import java.util.List;

@Getter
@Setter
public class ProjectDashboardResponse {

    private SummaryMetrics summary;
    private PortfolioProgress portfolioProgress;
    private MilestoneStatus milestoneStatus;
    private TaskStatusOverview taskStatus;
    private List<DelayedMilestoneItem> delayedMilestones;
    private List<UpcomingMilestoneItem> upcomingMilestones;
    private List<HighPriorityTaskItem> highPriorityTasks;
    private ForecastSummary forecastSummary;

    @Getter
    @Setter
    public static class SummaryMetrics {
        private int totalProjects;
        private int liveProjects;
        private double liveProjectsPercentage;
        private double overallProgress;
        private int delayedProjects;
        private double delayedProjectsPercentage;
        private int upcomingMilestonesCount;
        private int overdueTasksCount;
        private double overdueTasksPercentage;
    }

    @Getter
    @Setter
    public static class PortfolioProgress {
        private int completed;
        private int inProgress;
        private int notStarted;
        private int delayed;
        private int total;
    }

    @Getter
    @Setter
    public static class MilestoneStatus {
        private int completed;
        private int inProgress;
        private int notStarted;
        private int delayed;
        private int total;
    }

    @Getter
    @Setter
    public static class TaskStatusOverview {
        private int completed;
        private int inProgress;
        private int underReview;
        private int notStarted;
        private int overdue;
        private int total;
    }

    @Getter
    @Setter
    public static class DelayedMilestoneItem {
        private String milestoneTitle;
        private String projectCd;
        private long delayDays;
    }

    @Getter
    @Setter
    public static class UpcomingMilestoneItem {
        private String milestoneTitle;
        private String projectCd;
        private String dueDate;
        private String status;
    }

    @Getter
    @Setter
    public static class HighPriorityTaskItem {
        private String taskNm;
        private String projectCd;
        private String assigneeNm;
        private String dueDate;
    }

    @Getter
    @Setter
    public static class ForecastSummary {
        private double currentProgress;
        private double plannedProgress;
        private double variance;
        private String expectedCompletionDate;
        private int daysAhead;
        private int projectsAtRiskCount;
        private double projectsAtRiskPercentage;
        private int onTrackProjectsCount;
        private double onTrackProjectsPercentage;
        private int mayDelayProjectsCount;
        private double mayDelayProjectsPercentage;
        private int atRiskProjectsCount;
        private double atRiskProjectsPercentage;
    }
}
