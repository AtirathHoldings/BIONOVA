package com.bionova.service;

import com.bionova.config.CacheConfig;
import com.bionova.dto.AdminDashboardResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
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
 * Results are cached in Caffeine in-memory cache for fast dashboard loading.
 */
@Service
public class AdminDashboardService {

    @PersistenceContext
    private EntityManager entityManager;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Cacheable(value = CacheConfig.CACHE_ADMIN_DASHBOARD)
    public AdminDashboardResponse getDashboardData() {
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

    @CacheEvict(value = CacheConfig.CACHE_ADMIN_DASHBOARD, allEntries = true)
    public void evictAdminDashboardCache() {
    }

    private AdminDashboardResponse mapToResponse(JsonNode root) {
        JsonNode projStatus = root.path("projectStatus");
        JsonNode msProgress = root.path("milestoneProgress");
        JsonNode taskOv     = root.path("taskOverview");

        // projectStatusOverview map
        Map<String, Long> projectStatusOverview = new HashMap<>();
        projectStatusOverview.put("Total Projects", projStatus.path("total").asLong());
        projectStatusOverview.put("On Track",       projStatus.path("onTrack").asLong());
        projectStatusOverview.put("At Risk",        projStatus.path("atRisk").asLong());
        projectStatusOverview.put("Delayed",        projStatus.path("delayed").asLong());
        projectStatusOverview.put("Completed",      projStatus.path("completed").asLong());

        // milestoneProgress map
        Map<String, Object> milestoneProgressSummary = new HashMap<>();
        milestoneProgressSummary.put("Total",     msProgress.path("total").asLong());
        milestoneProgressSummary.put("Completed", msProgress.path("completed").asLong());
        milestoneProgressSummary.put("Progress",  msProgress.path("progress").asLong());
        milestoneProgressSummary.put("Overdue",   msProgress.path("overdue").asLong());

        // taskOverview map
        Map<String, Object> taskOverview = new HashMap<>();
        taskOverview.put("Total",     taskOv.path("total").asLong());
        taskOverview.put("Completed", taskOv.path("completed").asLong());
        taskOverview.put("Progress",  taskOv.path("progress").asLong());
        taskOverview.put("Todo",      taskOv.path("todo").asLong());
        taskOverview.put("Overdue",   taskOv.path("overdue").asLong());

        // systemActivities list
        List<AdminDashboardResponse.ActivityDto> systemActivities = new ArrayList<>();
        for (JsonNode a : root.path("systemActivities")) {
            systemActivities.add(new AdminDashboardResponse.ActivityDto(
                    a.path("description").asText(),
                    a.path("actor").asText(),
                    a.path("timestamp").asText()
            ));
        }

        // upcomingDeadlines list
        List<AdminDashboardResponse.DeadlineDto> upcomingDeadlines = new ArrayList<>();
        for (JsonNode d : root.path("upcomingDeadlines")) {
            upcomingDeadlines.add(new AdminDashboardResponse.DeadlineDto(
                    d.path("title").asText(),
                    d.path("projectName").asText(),
                    LocalDate.parse(d.path("dueDate").asText()),
                    d.path("timeLeft").asText(),
                    d.path("isCritical").asBoolean()
            ));
        }

        // topProjects list
        List<AdminDashboardResponse.ProjectProgressDto> topProjects = new ArrayList<>();
        for (JsonNode p : root.path("topProjects")) {
            topProjects.add(new AdminDashboardResponse.ProjectProgressDto(
                    p.path("projectId").asLong(),
                    p.path("projectName").asText(),
                    p.path("projectCode").asText(),
                    p.path("progressPercent").asDouble()
            ));
        }

        return new AdminDashboardResponse(
                root.path("employeeCount").asLong(),
                root.path("departmentCount").asLong(),
                root.path("companyCount").asLong(),
                root.path("plantCount").asLong(),
                root.path("activeProjectsCount").asLong(),
                root.path("criticalAlertsCount").asLong(),
                projectStatusOverview,
                milestoneProgressSummary,
                taskOverview,
                systemActivities,
                upcomingDeadlines,
                topProjects
        );
    }
}
