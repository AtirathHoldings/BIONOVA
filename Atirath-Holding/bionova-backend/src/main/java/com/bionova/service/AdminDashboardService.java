package com.bionova.service;

import com.bionova.dto.AdminDashboardResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Calls the Supabase stored procedure get_admin_dashboard()
 * which replaces 6 separate repository queries with a single DB round-trip.
 *
 * Procedure returns JSON:
 *   employeeCount, departmentCount, companyCount, plantCount,
 *   activeProjectsCount, criticalAlertsCount,
 *   projectStatus   { total, onTrack, atRisk, delayed, completed }
 *   milestoneProgress { total, completed, progress, overdue }
 *   taskOverview    { total, completed, progress, todo, overdue }
 *   topProjects     [ { projectId, projectName, projectCode, progressPercent } ]
 *   upcomingDeadlines [ { title, projectName, dueDate, timeLeft, isCritical } ]
 *   systemActivities  [ { description, actor, timestamp } ]
 */
@Service
public class AdminDashboardService {

    @PersistenceContext
    private EntityManager entityManager;

    private final ObjectMapper objectMapper = new ObjectMapper();

    public AdminDashboardResponse getDashboardData() {
        // Single stored procedure call — replaces all previous repository calls
        Object result = entityManager
                .createNativeQuery("SELECT get_admin_dashboard()")
                .getSingleResult();

        try {
            JsonNode root = objectMapper.readTree(result.toString());
            return mapToResponse(root);
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse get_admin_dashboard() response", e);
        }
    }

    private AdminDashboardResponse mapToResponse(JsonNode root) {
        JsonNode projStatus = root.path("projectStatus");
        JsonNode msProgress = root.path("milestoneProgress");
        JsonNode taskOv     = root.path("taskOverview");

        // projectStatusOverview map
        Map<String, Long> projectStatusOverview = new HashMap<>();
        projectStatusOverview.put("Total Projects", projStatus.path("total").asLong());
        projectStatusOverview.put("On Track",       projStatus.path("onTrack").asLong());
        projectStatusOverview.put("At Risk",         projStatus.path("atRisk").asLong());
        projectStatusOverview.put("Delayed",         projStatus.path("delayed").asLong());
        projectStatusOverview.put("Completed",       projStatus.path("completed").asLong());

        // milestoneProgress map
        Map<String, Object> milestoneProgress = new HashMap<>();
        milestoneProgress.put("total",     msProgress.path("total").asLong());
        milestoneProgress.put("completed", msProgress.path("completed").asLong());
        milestoneProgress.put("progress",  msProgress.path("progress").asLong());
        milestoneProgress.put("overdue",   msProgress.path("overdue").asLong());
        milestoneProgress.put("percentage",      msProgress.path("percentage").asDouble());
        milestoneProgress.put("progressPercent", msProgress.path("progressPercent").asDouble());

        // taskOverview map
        Map<String, Object> taskOverview = new HashMap<>();
        taskOverview.put("total",     taskOv.path("total").asLong());
        taskOverview.put("completed", taskOv.path("completed").asLong());
        taskOverview.put("progress",  taskOv.path("progress").asLong());
        taskOverview.put("todo",      taskOv.path("todo").asLong());
        taskOverview.put("overdue",   taskOv.path("overdue").asLong());

        // topProjects list
        List<AdminDashboardResponse.ProjectProgressDto> topProjects = new ArrayList<>();
        for (JsonNode p : root.path("topProjects")) {
            topProjects.add(AdminDashboardResponse.ProjectProgressDto.builder()
                    .projectId(p.path("projectId").asLong())
                    .projectName(p.path("projectName").asText())
                    .projectCode(p.path("projectCode").asText())
                    .progressPercent(p.path("progressPercent").asDouble())
                    .build());
        }

        // upcomingDeadlines list
        List<AdminDashboardResponse.DeadlineDto> upcomingDeadlines = new ArrayList<>();
        for (JsonNode d : root.path("upcomingDeadlines")) {
            String dueDateStr = d.path("dueDate").asText(null);
            LocalDate dueDate = (dueDateStr != null && !dueDateStr.isBlank())
                    ? LocalDate.parse(dueDateStr) : null;
            upcomingDeadlines.add(AdminDashboardResponse.DeadlineDto.builder()
                    .title(d.path("title").asText())
                    .projectName(d.path("projectName").asText())
                    .dueDate(dueDate)
                    .timeLeft(d.path("timeLeft").asText())
                    .isCritical(d.path("isCritical").asBoolean())
                    .build());
        }

        // systemActivities list
        List<AdminDashboardResponse.ActivityDto> systemActivities = new ArrayList<>();
        for (JsonNode a : root.path("systemActivities")) {
            systemActivities.add(AdminDashboardResponse.ActivityDto.builder()
                    .description(a.path("description").asText())
                    .actor(a.path("actor").asText())
                    .timestamp(a.path("timestamp").asText())
                    .build());
        }

        return AdminDashboardResponse.builder()
                .employeeCount(root.path("employeeCount").asLong())
                .departmentCount(root.path("departmentCount").asLong())
                .companyCount(root.path("companyCount").asLong())
                .plantCount(root.path("plantCount").asLong())
                .activeProjectsCount(root.path("activeProjectsCount").asLong())
                .criticalAlertsCount(root.path("criticalAlertsCount").asLong())
                .projectStatusOverview(projectStatusOverview)
                .milestoneProgress(milestoneProgress)
                .taskOverview(taskOverview)
                .topProjects(topProjects)
                .upcomingDeadlines(upcomingDeadlines)
                .systemActivities(systemActivities)
                .build();
    }
}
