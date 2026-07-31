package com.bionova.service;

import com.bionova.dto.ProjectDashboardResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Calls the Supabase stored procedure get_pm_dashboard()
 * which replaces 5 separate repository queries with a single DB round-trip.
 *
 * Procedure returns JSON matching ProjectDashboardResponse structure:
 *   summary, portfolioProgress, milestoneStatus, taskStatus,
 *   forecastSummary, delayedMilestones, upcomingMilestones, highPriorityTasks
 */
@Service
public class ProjectDashboardService {

    @PersistenceContext
    private EntityManager entityManager;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public ProjectDashboardResponse getProjectManagerMetrics() {
        // Single stored procedure call — replaces all previous repository iteration
        Object result = entityManager
                .createNativeQuery("SELECT get_pm_dashboard()")
                .getSingleResult();

        try {
            JsonNode root = objectMapper.readTree(result.toString());
            return mapToResponse(root);
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse get_pm_dashboard() response", e);
        }
    }

    private ProjectDashboardResponse mapToResponse(JsonNode root) {
        ProjectDashboardResponse response = new ProjectDashboardResponse();

        // Summary
        JsonNode s = root.path("summary");
        ProjectDashboardResponse.SummaryMetrics summary = new ProjectDashboardResponse.SummaryMetrics();
        summary.setTotalProjects(s.path("totalProjects").asInt());
        summary.setLiveProjects(s.path("liveProjects").asInt());
        summary.setLiveProjectsPercentage(s.path("liveProjectsPercentage").asDouble());
        summary.setOverallProgress(s.path("overallProgress").asDouble());
        summary.setDelayedProjects(s.path("delayedProjects").asInt());
        summary.setDelayedProjectsPercentage(s.path("delayedProjectsPercentage").asDouble());
        summary.setUpcomingMilestonesCount(s.path("upcomingMilestonesCount").asInt());
        summary.setOverdueTasksCount(s.path("overdueTasksCount").asInt());
        summary.setOverdueTasksPercentage(s.path("overdueTasksPercentage").asDouble());
        response.setSummary(summary);

        // Portfolio Progress (Doughnut 1)
        JsonNode pp = root.path("portfolioProgress");
        ProjectDashboardResponse.PortfolioProgress portfolio = new ProjectDashboardResponse.PortfolioProgress();
        portfolio.setCompleted(pp.path("completed").asInt());
        portfolio.setInProgress(pp.path("inProgress").asInt());
        portfolio.setNotStarted(pp.path("notStarted").asInt());
        portfolio.setDelayed(pp.path("delayed").asInt());
        portfolio.setTotal(pp.path("total").asInt());
        response.setPortfolioProgress(portfolio);

        // Milestone Status (Doughnut 2)
        JsonNode ms = root.path("milestoneStatus");
        ProjectDashboardResponse.MilestoneStatus milestoneStatus = new ProjectDashboardResponse.MilestoneStatus();
        milestoneStatus.setCompleted(ms.path("completed").asInt());
        milestoneStatus.setInProgress(ms.path("inProgress").asInt());
        milestoneStatus.setNotStarted(ms.path("notStarted").asInt());
        milestoneStatus.setDelayed(ms.path("delayed").asInt());
        milestoneStatus.setTotal(ms.path("total").asInt());
        response.setMilestoneStatus(milestoneStatus);

        // Task Status (Doughnut 3)
        JsonNode ts = root.path("taskStatus");
        ProjectDashboardResponse.TaskStatusOverview taskStatus = new ProjectDashboardResponse.TaskStatusOverview();
        taskStatus.setCompleted(ts.path("completed").asInt());
        taskStatus.setInProgress(ts.path("inProgress").asInt());
        taskStatus.setUnderReview(ts.path("underReview").asInt());
        taskStatus.setNotStarted(ts.path("notStarted").asInt());
        taskStatus.setOverdue(ts.path("overdue").asInt());
        taskStatus.setTotal(ts.path("total").asInt());
        response.setTaskStatus(taskStatus);

        // Forecast Summary
        JsonNode fs = root.path("forecastSummary");
        ProjectDashboardResponse.ForecastSummary forecast = new ProjectDashboardResponse.ForecastSummary();
        forecast.setCurrentProgress(fs.path("currentProgress").asDouble());
        forecast.setPlannedProgress(fs.path("plannedProgress").asDouble());
        forecast.setVariance(fs.path("variance").asDouble());
        forecast.setExpectedCompletionDate(fs.path("expectedCompletionDate").asText(null));
        forecast.setDaysAhead(fs.path("daysAhead").asInt());
        forecast.setProjectsAtRiskCount(fs.path("projectsAtRiskCount").asInt());
        forecast.setProjectsAtRiskPercentage(fs.path("projectsAtRiskPercentage").asDouble());
        forecast.setOnTrackProjectsCount(fs.path("onTrackProjectsCount").asInt());
        forecast.setOnTrackProjectsPercentage(fs.path("onTrackProjectsPercentage").asDouble());
        forecast.setMayDelayProjectsCount(fs.path("mayDelayProjectsCount").asInt());
        forecast.setMayDelayProjectsPercentage(fs.path("mayDelayProjectsPercentage").asDouble());
        forecast.setAtRiskProjectsCount(fs.path("atRiskProjectsCount").asInt());
        forecast.setAtRiskProjectsPercentage(fs.path("atRiskProjectsPercentage").asDouble());
        response.setForecastSummary(forecast);

        // Delayed Milestones
        List<ProjectDashboardResponse.DelayedMilestoneItem> delayedMs = new ArrayList<>();
        for (JsonNode d : root.path("delayedMilestones")) {
            ProjectDashboardResponse.DelayedMilestoneItem item = new ProjectDashboardResponse.DelayedMilestoneItem();
            item.setMilestoneTitle(d.path("milestoneTitle").asText());
            item.setProjectCd(d.path("projectCd").asText());
            item.setDelayDays(d.path("delayDays").asLong());
            delayedMs.add(item);
        }
        response.setDelayedMilestones(delayedMs);

        // Upcoming Milestones
        List<ProjectDashboardResponse.UpcomingMilestoneItem> upcomingMs = new ArrayList<>();
        for (JsonNode u : root.path("upcomingMilestones")) {
            ProjectDashboardResponse.UpcomingMilestoneItem item = new ProjectDashboardResponse.UpcomingMilestoneItem();
            item.setMilestoneTitle(u.path("milestoneTitle").asText());
            item.setProjectCd(u.path("projectCd").asText());
            item.setDueDate(u.path("dueDate").asText());
            item.setStatus(u.path("status").asText());
            upcomingMs.add(item);
        }
        response.setUpcomingMilestones(upcomingMs);

        // High Priority Tasks
        List<ProjectDashboardResponse.HighPriorityTaskItem> hpTasks = new ArrayList<>();
        for (JsonNode t : root.path("highPriorityTasks")) {
            ProjectDashboardResponse.HighPriorityTaskItem item = new ProjectDashboardResponse.HighPriorityTaskItem();
            item.setTaskNm(t.path("taskNm").asText());
            item.setProjectCd(t.path("projectCd").asText());
            item.setAssigneeNm(t.path("assigneeNm").asText());
            item.setDueDate(t.path("dueDate").asText());
            hpTasks.add(item);
        }
        response.setHighPriorityTasks(hpTasks);

        return response;
    }
}
