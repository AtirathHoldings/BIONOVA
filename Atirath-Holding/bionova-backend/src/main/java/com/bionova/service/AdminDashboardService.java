package com.bionova.service;

import com.bionova.dto.AdminDashboardResponse;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminDashboardService {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    public AdminDashboardResponse getDashboardData() {
        LocalDate today = LocalDate.now();

        // 1. Workforce Strength (Employee Count)
        long employeeCount = employeeRepository.count();

        // 2. Active Departments
        long departmentCount = departmentRepository.count();

        // Fetch all live projects, milestones, tasks
        List<ProjectLive> projects = projectLiveRepository.findAll();
        List<MilestoneLive> milestones = milestoneLiveRepository.findAll();
        List<TaskLive> tasks = taskLiveRepository.findAll();

        long activeProjectsCount = projects.size();

        // 3. Project Status Overview
        long completedProjects = 0;
        long delayedProjects = 0;
        long atRiskProjects = 0;
        long inProgressProjects = 0;
        long onTrackProjects = 0;

        for (ProjectLive prj : projects) {
            String status = prj.getPrjSts();
            LocalDate endDt = prj.getEndDt();

            if ("CLOSED".equalsIgnoreCase(status)) {
                completedProjects++;
            } else {
                // Active projects (LIVE, HOLD, etc.)
                if (endDt != null) {
                    if (endDt.isBefore(today)) {
                        delayedProjects++;
                    } else if (endDt.isBefore(today.plusDays(7))) {
                        atRiskProjects++;
                    } else {
                        onTrackProjects++;
                        inProgressProjects++;
                    }
                } else {
                    onTrackProjects++;
                }
            }
        }

        Map<String, Long> projectStatusOverview = new HashMap<>();
        projectStatusOverview.put("Total Projects", activeProjectsCount);
        projectStatusOverview.put("On Track", onTrackProjects);
        projectStatusOverview.put("In Progress", inProgressProjects);
        projectStatusOverview.put("At Risk", atRiskProjects);
        projectStatusOverview.put("Delayed", delayedProjects);
        projectStatusOverview.put("Completed", completedProjects);

        // 4. Milestone Progress
        long totalMilestones = milestones.size();
        long completedMilestones = 0;
        long inProgressMilestones = 0;
        long overdueMilestones = 0;

        for (MilestoneLive ms : milestones) {
            String status = ms.getMlstnSts();
            LocalDate endDt = ms.getEndDt();

            if ("COMPLETED".equalsIgnoreCase(status) || "CLOSED".equalsIgnoreCase(status)) {
                completedMilestones++;
            } else {
                inProgressMilestones++;
                if (endDt != null && endDt.isBefore(today)) {
                    overdueMilestones++;
                }
            }
        }

        Map<String, Object> milestoneProgress = new HashMap<>();
        milestoneProgress.put("total", totalMilestones);
        milestoneProgress.put("completed", completedMilestones);
        milestoneProgress.put("progress", inProgressMilestones);
        milestoneProgress.put("overdue", overdueMilestones);

        // 5. Task Status Overview
        long totalTasks = tasks.size();
        long completedTasks = 0;
        long inProgressTasks = 0;
        long todoTasks = 0;
        long overdueTasks = 0;

        for (TaskLive task : tasks) {
            String status = task.getTaskSts();
            LocalDate endDt = task.getEndDt();

            if ("COMPLETED".equalsIgnoreCase(status)) {
                completedTasks++;
            } else {
                if ("WIP".equalsIgnoreCase(status) || "SUBMIT_REVIEW".equalsIgnoreCase(status) || "UNDER_REVIEW".equalsIgnoreCase(status)) {
                    inProgressTasks++;
                } else {
                    todoTasks++;
                }

                if (endDt != null && endDt.isBefore(today)) {
                    overdueTasks++;
                }
            }
        }

        Map<String, Object> taskOverview = new HashMap<>();
        taskOverview.put("total", totalTasks);
        taskOverview.put("completed", completedTasks);
        taskOverview.put("progress", inProgressTasks);
        taskOverview.put("todo", todoTasks);
        taskOverview.put("overdue", overdueTasks);

        // 6. Critical Alerts Count (Delayed projects + Overdue tasks)
        long criticalAlertsCount = delayedProjects + overdueTasks;

        // 7. System Activity Log (Mock some standard activities if none exist, or query database updates)
        List<AdminDashboardResponse.ActivityDto> systemActivities = new ArrayList<>();
        
        // Dynamically add activities based on recent projects
        List<ProjectLive> sortedProjects = projects.stream()
                .sorted((p1, p2) -> p2.getPrjId().compareTo(p1.getPrjId()))
                .limit(3)
                .collect(Collectors.toList());

        for (ProjectLive prj : sortedProjects) {
            String suffix = prj.getPrjCd() != null ? " (" + prj.getPrjCd() + ")" : "";
            systemActivities.add(AdminDashboardResponse.ActivityDto.builder()
                    .description("Project \"" + prj.getPrjNm() + suffix + "\" initiated in Live status")
                    .actor("System Admin")
                    .timestamp("Recent")
                    .build());
        }

        // Add some completed milestone activities
        List<MilestoneLive> completedMss = milestones.stream()
                .filter(ms -> "COMPLETED".equalsIgnoreCase(ms.getMlstnSts()))
                .limit(2)
                .collect(Collectors.toList());

        for (MilestoneLive ms : completedMss) {
            systemActivities.add(AdminDashboardResponse.ActivityDto.builder()
                    .description("Milestone \"" + ms.getMlstnTtl() + "\" marked as COMPLETED")
                    .actor("Project Manager")
                    .timestamp("Recent")
                    .build());
        }

        // No fallback — if no activities, return empty list

        // 8. Upcoming Deadlines
        List<AdminDashboardResponse.DeadlineDto> upcomingDeadlines = new ArrayList<>();
        
        // Scan for pending tasks ending in the next 14 days
        List<TaskLive> pendingTasks = tasks.stream()
                .filter(t -> !"COMPLETED".equalsIgnoreCase(t.getTaskSts()))
                .filter(t -> t.getEndDt() != null)
                .sorted(Comparator.comparing(TaskLive::getEndDt))
                .limit(5)
                .collect(Collectors.toList());

        for (TaskLive t : pendingTasks) {
            long daysLeft = ChronoUnit.DAYS.between(today, t.getEndDt());
            String timeLeftText = daysLeft < 0 ? "Overdue" : daysLeft + " Days Left";
            boolean isCritical = daysLeft <= 2;

            // Find project name for this task
            String prjName = "Live Project";
            Optional<MilestoneLive> msOpt = milestones.stream()
                    .filter(m -> m.getMId().equals(t.getMId()))
                    .findFirst();
            if (msOpt.isPresent()) {
                Long prjId = msOpt.get().getPrjId();
                Optional<ProjectLive> prjOpt = projects.stream()
                        .filter(p -> p.getPrjId().equals(prjId))
                        .findFirst();
                if (prjOpt.isPresent()) {
                    ProjectLive prj = prjOpt.get();
                    String suffix = prj.getPrjCd() != null ? " (" + prj.getPrjCd() + ")" : "";
                    prjName = prj.getPrjNm() + suffix;
                }
            }

            String taskSuffix = t.getTaskCd() != null ? " (" + t.getTaskCd() + ")" : "";
            upcomingDeadlines.add(AdminDashboardResponse.DeadlineDto.builder()
                    .title(t.getTaskNm() + taskSuffix)
                    .projectName(prjName)
                    .dueDate(t.getEndDt())
                    .timeLeft(timeLeftText)
                    .isCritical(isCritical)
                    .build());
        }

        // No fallback — if no deadlines, return empty list

        // 9. Top Projects Tracker (calculating progress percent dynamically)
        List<AdminDashboardResponse.ProjectProgressDto> topProjects = new ArrayList<>();
        
        for (ProjectLive prj : projects) {
            // Find milestones for this project
            List<Long> msIds = milestones.stream()
                    .filter(m -> m.getPrjId().equals(prj.getPrjId()))
                    .map(MilestoneLive::getMId)
                    .collect(Collectors.toList());

            long totalPrjTasks = 0;
            long completedPrjTasks = 0;

            if (!msIds.isEmpty()) {
                List<TaskLive> prjTasks = tasks.stream()
                        .filter(t -> msIds.contains(t.getMId()))
                        .collect(Collectors.toList());
                totalPrjTasks = prjTasks.size();
                completedPrjTasks = prjTasks.stream()
                        .filter(t -> "COMPLETED".equalsIgnoreCase(t.getTaskSts()))
                        .count();
            }

            double progressPercent = 0.0;
            if (totalPrjTasks > 0) {
                progressPercent = Math.round(((double) completedPrjTasks / totalPrjTasks) * 100.0);
            } else if ("CLOSED".equalsIgnoreCase(prj.getPrjSts())) {
                progressPercent = 100.0;
            } else {
                progressPercent = 0.0; // fallback default of 0.0 instead of 45.0
            }

            topProjects.add(AdminDashboardResponse.ProjectProgressDto.builder()
                    .projectId(prj.getPrjId())
                    .projectName(prj.getPrjNm())
                    .projectCode(prj.getPrjCd())
                    .progressPercent(progressPercent)
                    .build());
        }

        // Sort by progress percent descending
        topProjects.sort((p1, p2) -> Double.compare(p2.getProgressPercent(), p1.getProgressPercent()));
        
        // Limit to top 5
        if (topProjects.size() > 5) {
            topProjects = topProjects.subList(0, 5);
        }

        // No fallback — if no projects, return empty list

        return AdminDashboardResponse.builder()
                .employeeCount(employeeCount)
                .departmentCount(departmentCount)
                .activeProjectsCount(activeProjectsCount)
                .criticalAlertsCount(criticalAlertsCount)
                .projectStatusOverview(projectStatusOverview)
                .milestoneProgress(milestoneProgress)
                .taskOverview(taskOverview)
                .systemActivities(systemActivities)
                .upcomingDeadlines(upcomingDeadlines)
                .topProjects(topProjects)
                .build();
    }
}
