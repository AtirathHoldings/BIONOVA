package com.bionova.controller;

import com.bionova.dto.UserDashboardResponseDto;
import com.bionova.dto.UserDashboardResponseDto.*;
import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * REST controller for User Dashboard.
 * Maps data returned by get_user_dashboard(p_emp_id) stored procedure.
 */
@RestController
@RequestMapping("/api/user-dashboard")
public class UserDashboardController {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private com.bionova.service.ProjectLeadLagService leadLagService;

    @PersistenceContext
    private EntityManager entityManager;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @GetMapping
    public ResponseEntity<?> getDashboardData() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);

        if (employee == null) {
            return ResponseEntity.notFound().build();
        }

        Object result = entityManager
                .createNativeQuery("SELECT get_user_dashboard(:empId)")
                .setParameter("empId", employee.getEmpId())
                .getSingleResult();

        try {
            JsonNode root = objectMapper.readTree(result.toString());
            return ResponseEntity.ok(mapToResponse(root, employee.getEmpId()));
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse get_user_dashboard() response", e);
        }
    }

    @GetMapping("/my-tasks")
    public ResponseEntity<?> getMyTasksData() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);

        if (employee == null) {
            return ResponseEntity.notFound().build();
        }

        Object result = entityManager
                .createNativeQuery("SELECT get_my_tasks_data(:empId)")
                .setParameter("empId", employee.getEmpId())
                .getSingleResult();

        try {
            JsonNode root = objectMapper.readTree(result.toString());
            return ResponseEntity.ok(root);
        } catch (Exception e) {
            throw new RuntimeException("Failed to parse get_my_tasks_data() response", e);
        }
    }

    private UserDashboardResponseDto mapToResponse(JsonNode root, Long empId) {
        JsonNode profile = root.path("profile");
        JsonNode summary = root.path("summary");
        JsonNode counts = root.path("taskStatusCounts");

        // 1. To-Do List Mapping
        List<TodoTaskDto> todoList = new ArrayList<>();
        for (JsonNode t : root.path("todoList")) {
            todoList.add(new TodoTaskDto(
                    t.path("taskId").asLong(),
                    t.path("taskNm").asText(),
                    t.path("project").asText("Internal"),
                    t.path("priority").asText("Medium"),
                    parseDate(t.path("endDt").asText(null)),
                    t.path("status").asText("Open"),
                    t.path("isOverdue").asBoolean(),
                    t.path("isDueToday").asBoolean(),
                    t.path("badge").asText("Executor"),
                    t.path("taskSource").asText("PROJECT"),
                    mapEmployees(t.path("employees"))
            ));
        }

        // 2. Upcoming Tasks Mapping
        List<UpcomingTaskDto> upcomingTasks = new ArrayList<>();
        for (JsonNode t : root.path("upcomingTasks")) {
            upcomingTasks.add(new UpcomingTaskDto(
                    t.path("taskId").asLong(),
                    t.path("taskNm").asText(),
                    t.path("prjCd").asText("Internal"),
                    parseDate(t.path("stDt").asText(null)),
                    parseDate(t.path("endDt").asText(null)),
                    t.path("durationDays").asInt(0),
                    t.path("priority").asText("Medium"),
                    mapEmployees(t.path("employees"))
            ));
        }

        // 3. My Projects Mapping
        List<UserProjectDto> myProjects = new ArrayList<>();
        for (JsonNode p : root.path("myProjects")) {
            Long projectId = p.path("projectId").asLong(0);

            // Fetch Lead/Lag status for this project
            String leadLagStatus = null;
            String leadLagLabel  = null;
            String leadLagColor  = null;
            int    daysVariance  = 0;
            if (projectId > 0) {
                try {
                    java.util.Map<String, Object> ll = leadLagService.getLeadLagDetail(projectId);
                    leadLagStatus = (String) ll.get("leadLagStatus");
                    leadLagLabel  = (String) ll.get("leadLagLabel");
                    leadLagColor  = (String) ll.get("leadLagColor");
                    Object dv = ll.get("daysVariance");
                    if (dv instanceof Number n) daysVariance = n.intValue();
                } catch (Exception ignored) { /* project not live yet */ }
            }

            myProjects.add(new UserProjectDto(
                    projectId,
                    p.path("projectName").asText(),
                    p.path("projectCode").asText(),
                    p.path("clientName").asText(""),
                    p.path("plantName").asText(""),
                    p.path("location").asText(""),
                    p.path("role").asText(profile.path("role").asText("Site Engineer")),
                    p.path("progress").asDouble(),
                    p.path("tasksAssigned").asInt(),
                    p.path("openTasks").asInt(),
                    p.path("closedTasks").asInt(),
                    p.path("status").asText("In Progress"),
                    p.path("logo").asText(null),
                    parseDate(p.path("dueDate").asText(null)),
                    leadLagStatus,
                    leadLagLabel,
                    leadLagColor,
                    daysVariance
            ));
        }

        // 4. Task Status Counts (Donut Chart) Mapping
        int completedVal = counts.path("Completed").asInt();
        int inProgressVal = counts.path("In Progress").asInt();
        int underReviewVal = counts.path("Under Review").asInt();
        int overdueVal = counts.path("Overdue").asInt();
        int openVal = counts.path("Open").asInt();
        int reassignedVal = counts.path("Reassigned").asInt();
        int reworkVal = counts.path("Rework").asInt();
        int draftVal = counts.path("Draft").asInt();

        Map<String, Integer> taskStatusCounts = new HashMap<>();
        taskStatusCounts.put("Completed",    completedVal);
        taskStatusCounts.put("In Progress",  inProgressVal);
        taskStatusCounts.put("Under Review", underReviewVal);
        taskStatusCounts.put("Overdue",      overdueVal);
        taskStatusCounts.put("Open",         openVal);
        taskStatusCounts.put("Reassigned",   reassignedVal);
        taskStatusCounts.put("Rework",       reworkVal);
        taskStatusCounts.put("Draft",        draftVal);

        int mainCompleted = counts.path("MainCompleted").asInt();
        int mainWip = counts.path("MainWIP").asInt();
        int mainOpen = counts.path("MainOpen").asInt();

        double total = mainCompleted + mainWip + mainOpen;

        Map<String, Integer> taskStatusPercentages = new HashMap<>();
        if (total > 0) {
            taskStatusPercentages.put("Completed",    (int) Math.round((mainCompleted / total) * 100));
            taskStatusPercentages.put("In Progress",  (int) Math.round((mainWip / total) * 100));
            taskStatusPercentages.put("Open",         (int) Math.round((mainOpen / total) * 100));
            taskStatusPercentages.put("Under Review", 0);
            taskStatusPercentages.put("Overdue",      0);
            taskStatusPercentages.put("Reassigned",   0);
            taskStatusPercentages.put("Rework",       0);
            taskStatusPercentages.put("Draft",        0);
        } else {
            taskStatusPercentages.put("Completed",    0);
            taskStatusPercentages.put("In Progress",  0);
            taskStatusPercentages.put("Open",         0);
            taskStatusPercentages.put("Under Review", 0);
            taskStatusPercentages.put("Overdue",      0);
            taskStatusPercentages.put("Reassigned",   0);
            taskStatusPercentages.put("Rework",       0);
            taskStatusPercentages.put("Draft",        0);
        }

        // 5. Recent Activity Feed Mapping
        List<RecentActivityDto> recentActivity = new ArrayList<>();
        for (JsonNode act : root.path("recentActivity")) {
            recentActivity.add(new RecentActivityDto(
                    act.path("logId").asLong(),
                    act.path("entityTyp").asText(),
                    act.path("entityId").asLong(),
                    act.path("statusFrom").asText(),
                    act.path("statusTo").asText(),
                    act.path("logDt").asText(),
                    act.path("message").asText(),
                    act.path("projectName").asText()
            ));
        }

        // 6. Assemble DTO
        UserDashboardResponseDto dto = new UserDashboardResponseDto();
        dto.setFullName(profile.path("fullName").asText("User"));
        dto.setRole(profile.path("role").asText("Site Engineer"));
        dto.setDepartment(profile.path("department").asText("Projects Department"));
        dto.setPhotoUrl(profile.path("photoUrl").asText(null));

        int myProjectsCount = summary.path("myProjectsCount").asInt();
        int myTasksCount = summary.path("myTasksCount").asInt();
        int dueTodayCount = summary.path("dueTodayCount").asInt();
        int overdueTasksCount = summary.path("overdueTasksCount").asInt();
        int completedTasksCount = summary.path("completedTasksCount").asInt();

        dto.setMyProjectsCount(myProjectsCount);
        dto.setMyTasksCount(myTasksCount);
        dto.setDueTodayCount(dueTodayCount);
        dto.setOverdueTasksCount(overdueTasksCount);
        dto.setCompletedTasksCount(completedTasksCount);

        JsonNode trendsNode = root.path("metricsTrends");
        dto.setAssignedTasksCard(mapMetricCard(trendsNode.path("assignedTasks"), (int) total));
        dto.setOpenTasksCard(mapMetricCard(trendsNode.path("openTasks"), counts.path("Open").asInt() + counts.path("Draft").asInt()));
        dto.setInProgressCard(mapMetricCard(trendsNode.path("inProgress"), counts.path("In Progress").asInt()));
        dto.setOverdueTasksCard(mapMetricCard(trendsNode.path("overdueTasks"), overdueTasksCount));
        dto.setCompletedTasksCard(mapMetricCard(trendsNode.path("completedTasks"), completedTasksCount));
        dto.setMyProjectsCard(mapMetricCard(trendsNode.path("myProjects"), myProjectsCount));

        dto.setTodoList(todoList);
        dto.setUpcomingTasks(upcomingTasks);
        dto.setMyProjects(myProjects);
        dto.setTaskStatusCounts(taskStatusCounts);
        dto.setTaskStatusPercentages(taskStatusPercentages);
        dto.setOverallCompletionPercentage(summary.path("overallCompletion").asDouble());

        // Calculate Milestone Progress
        List<MilestoneLive> userMilestones = milestoneLiveRepository.findMilestonesByEmpId(empId);
        int msCompleted = 0, msInProgress = 0, msOpen = 0, msDelayed = 0;
        LocalDate today = LocalDate.now();
        for (MilestoneLive m : userMilestones) {
            String sts = m.getMlstnSts() != null ? m.getMlstnSts().toUpperCase() : "LIVE";
            if (sts.equals("COMPLETED") || sts.equals("CLOSED")) {
                msCompleted++;
            } else if (sts.equals("HOLD")) {
                msDelayed++;
            } else {
                // It is LIVE or other active state
                if (m.getEndDt() != null && today.isAfter(m.getEndDt())) {
                    msDelayed++;
                } else if (m.getStDt() != null && today.isBefore(m.getStDt())) {
                    msOpen++; // Not started yet
                } else {
                    msInProgress++;
                }
            }
        }
        Map<String, Integer> milestoneStatus = new HashMap<>();
        milestoneStatus.put("total", userMilestones.size());
        milestoneStatus.put("completed", msCompleted);
        milestoneStatus.put("inProgress", msInProgress);
        milestoneStatus.put("notStarted", msOpen);
        milestoneStatus.put("delayed", msDelayed);
        dto.setMilestoneStatus(milestoneStatus);

        JsonNode performanceNode = root.path("performance");
        dto.setProductivity(mapPerformanceMetric(performanceNode.path("productivity")));
        dto.setTaskCompletion(mapPerformanceMetric(performanceNode.path("taskCompletion")));
        dto.setQualityScore(mapPerformanceMetric(performanceNode.path("qualityScore")));

        dto.setRecentActivity(recentActivity);

        return dto;
    }

    private MetricCardDto mapMetricCard(JsonNode cardNode, int currentCount) {
        if (cardNode == null || cardNode.isMissingNode()) {
            return new MetricCardDto(currentCount, 0, new ArrayList<>());
        }
        List<Integer> trend = new ArrayList<>();
        JsonNode trendNode = cardNode.path("trend");
        if (trendNode.isArray()) {
            for (JsonNode val : trendNode) {
                trend.add(val.asInt());
            }
        }
        return new MetricCardDto(
                currentCount,
                cardNode.path("weeklyChange").asInt(0),
                trend
        );
    }

    private List<EmployeeAvatarDto> mapEmployees(JsonNode empNodes) {
        List<EmployeeAvatarDto> list = new ArrayList<>();
        if (empNodes != null && empNodes.isArray()) {
            for (JsonNode n : empNodes) {
                list.add(new EmployeeAvatarDto(
                        n.path("empId").asLong(),
                        n.path("fullName").asText(),
                        n.path("photoUrl").asText(null),
                        n.path("role").asText("Executor")
                ));
            }
        }
        return list;
    }

    private PerformanceMetricDto mapPerformanceMetric(JsonNode node) {
        if (node == null || node.isMissingNode()) {
            return new PerformanceMetricDto(100, "Excellent");
        }
        return new PerformanceMetricDto(
                node.path("score").asInt(100),
                node.path("rating").asText("Excellent")
        );
    }

    private LocalDate parseDate(String dateStr) {
        if (dateStr == null || dateStr.isBlank() || dateStr.equals("null")) {
            return null;
        }
        try {
            return LocalDate.parse(dateStr);
        } catch (Exception e) {
            return null;
        }
    }
}
