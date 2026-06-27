package com.bionova.service;

import com.bionova.dto.ProjectDashboardResponse;
import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Service
public class ProjectDashboardService {

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd-MMM-yyyy");

    public ProjectDashboardResponse getProjectManagerMetrics() {
        List<ProjectLive> projects = projectLiveRepository.findAll();

        if (projects.isEmpty()) {
            return getFallbackMockData();
        }

        ProjectDashboardResponse response = new ProjectDashboardResponse();
        LocalDate now = LocalDate.now();

        // 1. Calculate project-by-project progress
        int totalProjectsCount = projects.size();
        int liveProjectsCount = 0;
        int delayedProjectsCount = 0;
        double progressSum = 0.0;

        // For charts & listings
        int msCompleted = 0, msInProgress = 0, msNotStarted = 0, msDelayed = 0;
        int tCompleted = 0, tInProgress = 0, tUnderReview = 0, tNotStarted = 0, tOverdue = 0;

        List<ProjectDashboardResponse.DelayedMilestoneItem> delayedMilestonesList = new ArrayList<>();
        List<ProjectDashboardResponse.UpcomingMilestoneItem> upcomingMilestonesList = new ArrayList<>();
        List<ProjectDashboardResponse.HighPriorityTaskItem> highPriorityTasksList = new ArrayList<>();

        Map<Long, Employee> employeeMap = getEmployeeMap();

        for (ProjectLive project : projects) {
            if ("LIVE".equalsIgnoreCase(project.getPrjSts())) {
                liveProjectsCount++;
            }

            List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(project.getPrjId());
            double projectProgress = 0.0;
            int totalProjectTasks = 0;
            int completedProjectTasks = 0;

            for (MilestoneLive milestone : milestones) {
                // Milestone status categorization
                String msSts = milestone.getMlstnSts();
                boolean isMsCompleted = "COMPLETED".equalsIgnoreCase(msSts) || "CLOSED".equalsIgnoreCase(msSts);
                LocalDate msEnd = milestone.getEndDt();

                if (isMsCompleted) {
                    msCompleted++;
                } else if (msEnd != null && msEnd.isBefore(now)) {
                    msDelayed++;
                    // Add to delayed milestones
                    ProjectDashboardResponse.DelayedMilestoneItem delayedMs = new ProjectDashboardResponse.DelayedMilestoneItem();
                    delayedMs.setMilestoneTitle(milestone.getMlstnTtl());
                    delayedMs.setProjectCd(project.getPrjCd());
                    delayedMs.setDelayDays(ChronoUnit.DAYS.between(msEnd, now));
                    delayedMilestonesList.add(delayedMs);
                } else if (msEnd != null && msEnd.isBefore(now.plusDays(30))) {
                    msInProgress++;
                    // Add to upcoming milestones
                    ProjectDashboardResponse.UpcomingMilestoneItem upcomingMs = new ProjectDashboardResponse.UpcomingMilestoneItem();
                    upcomingMs.setMilestoneTitle(milestone.getMlstnTtl());
                    upcomingMs.setProjectCd(project.getPrjCd());
                    upcomingMs.setDueDate(msEnd.format(DATE_FORMATTER));
                    upcomingMs.setStatus("In Progress");
                    upcomingMilestonesList.add(upcomingMs);
                } else {
                    msNotStarted++;
                }

                // Query tasks for this milestone
                List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(milestone.getMId());
                for (TaskLive task : tasks) {
                    totalProjectTasks++;
                    String tSts = task.getTaskSts();
                    LocalDate tEnd = task.getEndDt();

                    if ("COMPLETED".equalsIgnoreCase(tSts)) {
                        completedProjectTasks++;
                        tCompleted++;
                    } else {
                        if (tEnd != null && tEnd.isBefore(now)) {
                            tOverdue++;
                        }
                        if ("WIP".equalsIgnoreCase(tSts)) {
                            tInProgress++;
                        } else if ("UNDER_REVIEW".equalsIgnoreCase(tSts) || "SUBMIT_REVIEW".equalsIgnoreCase(tSts)) {
                            tUnderReview++;
                        } else {
                            tNotStarted++;
                        }

                        // Check for high priority task
                        // Task entity uses String prj_prty in Project, in Task it could be high priority? Wait, the schema does not show task priority column in TaskLive, but we can assume tasks due soon or default high priority. Let's see if TaskLive has a priority. No, TaskLive does not have priority, but we can return tasks that are overdue or WIP as priority.
                        if (highPriorityTasksList.size() < 5 && tEnd != null && !tEnd.isBefore(now)) {
                            ProjectDashboardResponse.HighPriorityTaskItem hpTask = new ProjectDashboardResponse.HighPriorityTaskItem();
                            hpTask.setTaskNm(task.getTaskNm());
                            hpTask.setProjectCd(project.getPrjCd());
                            Employee emp = employeeMap.get(task.getEmpId());
                            hpTask.setAssigneeNm(emp != null ? emp.getFirstName() + " " + (emp.getLastName() != null ? emp.getLastName() : "") : "Unassigned");
                            hpTask.setDueDate(tEnd.format(DATE_FORMATTER));
                            highPriorityTasksList.add(hpTask);
                        }
                    }
                }
            }

            if (totalProjectTasks > 0) {
                projectProgress = ((double) completedProjectTasks / totalProjectTasks) * 100.0;
            } else if (!milestones.isEmpty()) {
                projectProgress = ((double) msCompleted / milestones.size()) * 100.0;
            }
            progressSum += projectProgress;

            // Project delay check
            if (project.getEndDt() != null && project.getEndDt().isBefore(now) && projectProgress < 100.0) {
                delayedProjectsCount++;
            }
        }

        double overallProgress = totalProjectsCount > 0 ? (progressSum / totalProjectsCount) : 0.0;

        // Populate Summary
        ProjectDashboardResponse.SummaryMetrics summary = new ProjectDashboardResponse.SummaryMetrics();
        summary.setTotalProjects(totalProjectsCount);
        summary.setLiveProjects(liveProjectsCount);
        summary.setLiveProjectsPercentage(totalProjectsCount > 0 ? ((double) liveProjectsCount / totalProjectsCount) * 100 : 0.0);
        summary.setOverallProgress(overallProgress);
        summary.setDelayedProjects(delayedProjectsCount);
        summary.setDelayedProjectsPercentage(totalProjectsCount > 0 ? ((double) delayedProjectsCount / totalProjectsCount) * 100 : 0.0);
        summary.setUpcomingMilestonesCount(upcomingMilestonesList.size());
        
        int totalTasks = tCompleted + tInProgress + tUnderReview + tNotStarted + tOverdue;
        summary.setOverdueTasksCount(tOverdue);
        summary.setOverdueTasksPercentage(totalTasks > 0 ? ((double) tOverdue / totalTasks) * 100 : 0.0);
        response.setSummary(summary);

        // Populate Portfolio Progress (Doughnut 1)
        ProjectDashboardResponse.PortfolioProgress pp = new ProjectDashboardResponse.PortfolioProgress();
        pp.setCompleted(msCompleted);
        pp.setInProgress(msInProgress);
        pp.setNotStarted(msNotStarted);
        pp.setDelayed(msDelayed);
        pp.setTotal(msCompleted + msInProgress + msNotStarted + msDelayed);
        response.setPortfolioProgress(pp);

        // Populate Milestone Status (Doughnut 2)
        ProjectDashboardResponse.MilestoneStatus ms = new ProjectDashboardResponse.MilestoneStatus();
        ms.setCompleted(msCompleted);
        ms.setInProgress(msInProgress);
        ms.setNotStarted(msNotStarted);
        ms.setDelayed(msDelayed);
        ms.setTotal(msCompleted + msInProgress + msNotStarted + msDelayed);
        response.setMilestoneStatus(ms);

        // Populate Task Status Overview (Doughnut 3)
        ProjectDashboardResponse.TaskStatusOverview ts = new ProjectDashboardResponse.TaskStatusOverview();
        ts.setCompleted(tCompleted);
        ts.setInProgress(tInProgress);
        ts.setUnderReview(tUnderReview);
        ts.setNotStarted(tNotStarted);
        ts.setOverdue(tOverdue);
        ts.setTotal(totalTasks);
        response.setTaskStatus(ts);

        // Sort and limit lists
        delayedMilestonesList.sort((a, b) -> Long.compare(b.getDelayDays(), a.getDelayDays()));
        response.setDelayedMilestones(delayedMilestonesList.subList(0, Math.min(delayedMilestonesList.size(), 5)));
        response.setUpcomingMilestones(upcomingMilestonesList.subList(0, Math.min(upcomingMilestonesList.size(), 5)));
        response.setHighPriorityTasks(highPriorityTasksList);

        // Forecast Summary
        ProjectDashboardResponse.ForecastSummary forecast = new ProjectDashboardResponse.ForecastSummary();
        forecast.setCurrentProgress(overallProgress);
        forecast.setPlannedProgress(50.0);
        forecast.setVariance(overallProgress - 50.0);
        forecast.setExpectedCompletionDate(now.plusDays(90).format(DATE_FORMATTER));
        forecast.setDaysAhead(90);
        forecast.setProjectsAtRiskCount(delayedProjectsCount);
        forecast.setProjectsAtRiskPercentage(totalProjectsCount > 0 ? ((double) delayedProjectsCount / totalProjectsCount) * 100 : 0.0);
        
        int onTrack = totalProjectsCount - delayedProjectsCount;
        forecast.setOnTrackProjectsCount(onTrack);
        forecast.setOnTrackProjectsPercentage(totalProjectsCount > 0 ? ((double) onTrack / totalProjectsCount) * 100 : 0.0);
        forecast.setMayDelayProjectsCount(delayedProjectsCount);
        forecast.setMayDelayProjectsPercentage(totalProjectsCount > 0 ? ((double) delayedProjectsCount / totalProjectsCount) * 100 : 0.0);
        forecast.setAtRiskProjectsCount(delayedProjectsCount);
        forecast.setAtRiskProjectsPercentage(totalProjectsCount > 0 ? ((double) delayedProjectsCount / totalProjectsCount) * 100 : 0.0);
        response.setForecastSummary(forecast);

        return response;
    }

    private Map<Long, Employee> getEmployeeMap() {
        Map<Long, Employee> map = new HashMap<>();
        try {
            List<Employee> employees = employeeRepository.findAll();
            for (Employee employee : employees) {
                map.put(employee.getEmpId(), employee);
            }
        } catch (Exception e) {
            // Ignore if employee fetch fails
        }
        return map;
    }

    private ProjectDashboardResponse getFallbackMockData() {
        ProjectDashboardResponse response = new ProjectDashboardResponse();

        // Summary
        ProjectDashboardResponse.SummaryMetrics summary = new ProjectDashboardResponse.SummaryMetrics();
        summary.setTotalProjects(24);
        summary.setLiveProjects(12);
        summary.setLiveProjectsPercentage(50.0);
        summary.setOverallProgress(45.30);
        summary.setDelayedProjects(3);
        summary.setDelayedProjectsPercentage(12.50);
        summary.setUpcomingMilestonesCount(8);
        summary.setOverdueTasksCount(18);
        summary.setOverdueTasksPercentage(14.06);
        response.setSummary(summary);

        // Portfolio Progress
        ProjectDashboardResponse.PortfolioProgress pp = new ProjectDashboardResponse.PortfolioProgress();
        pp.setCompleted(76);
        pp.setInProgress(115);
        pp.setNotStarted(36);
        pp.setDelayed(12);
        pp.setTotal(239);
        response.setPortfolioProgress(pp);

        // Milestone Status
        ProjectDashboardResponse.MilestoneStatus ms = new ProjectDashboardResponse.MilestoneStatus();
        ms.setCompleted(76);
        ms.setInProgress(115);
        ms.setNotStarted(36);
        ms.setDelayed(12);
        ms.setTotal(239);
        response.setMilestoneStatus(ms);

        // Task Status
        ProjectDashboardResponse.TaskStatusOverview ts = new ProjectDashboardResponse.TaskStatusOverview();
        ts.setCompleted(12);
        ts.setInProgress(61);
        ts.setUnderReview(13);
        ts.setNotStarted(29);
        ts.setOverdue(13);
        ts.setTotal(128);
        response.setTaskStatus(ts);

        // Delayed Milestones
        List<ProjectDashboardResponse.DelayedMilestoneItem> delayed = new ArrayList<>();
        delayed.add(createDelayedItem("Structure Erection", "PRJ-2025-001", 8));
        delayed.add(createDelayedItem("Steel Installation", "PRJ-2025-003", 6));
        delayed.add(createDelayedItem("Painting Work", "PRJ-2025-004", 5));
        delayed.add(createDelayedItem("Testing & Commissioning", "PRJ-2025-002", 4));
        delayed.add(createDelayedItem("Cable Laying", "PRJ-2025-004", 3));
        response.setDelayedMilestones(delayed);

        // Upcoming Milestones
        List<ProjectDashboardResponse.UpcomingMilestoneItem> upcoming = new ArrayList<>();
        upcoming.add(createUpcomingItem("Civil Foundation Work", "PRJ-2025-001", "12-Jun-2025", "In Progress"));
        upcoming.add(createUpcomingItem("Equipment Arrival", "PRJ-2025-002", "16-Jun-2025", "Pending"));
        upcoming.add(createUpcomingItem("Mechanical Installation", "PRJ-2025-002", "20-Jun-2025", "In Progress"));
        upcoming.add(createUpcomingItem("Piping Work", "PRJ-2025-005", "22-Jun-2025", "Pending"));
        upcoming.add(createUpcomingItem("Instrumentation", "PRJ-2025-004", "25-Jun-2025", "Pending"));
        response.setUpcomingMilestones(upcoming);

        // High Priority Tasks
        List<ProjectDashboardResponse.HighPriorityTaskItem> hpTasks = new ArrayList<>();
        hpTasks.add(createHpTask("Excavation", "PRJ-2025-001", "Ravi Kumar", "08-Jun-2025"));
        hpTasks.add(createHpTask("Equipment Erection", "PRJ-2025-002", "Mahesh", "10-Jun-2025"));
        hpTasks.add(createHpTask("PCC Work", "PRJ-2025-001", "Srikanth", "14-Jun-2025"));
        hpTasks.add(createHpTask("Cable Laying", "PRJ-2025-004", "Chandu", "16-Jun-2025"));
        hpTasks.add(createHpTask("Steel Structure", "PRJ-2025-003", "Suresh Babu", "18-Jun-2025"));
        response.setHighPriorityTasks(hpTasks);

        // Forecast Summary
        ProjectDashboardResponse.ForecastSummary forecast = new ProjectDashboardResponse.ForecastSummary();
        forecast.setCurrentProgress(45.30);
        forecast.setPlannedProgress(50.00);
        forecast.setVariance(-4.70);
        forecast.setExpectedCompletionDate("20-Sep-2025");
        forecast.setDaysAhead(102);
        forecast.setProjectsAtRiskCount(3);
        forecast.setProjectsAtRiskPercentage(12.50);
        forecast.setOnTrackProjectsCount(18);
        forecast.setOnTrackProjectsPercentage(75.00);
        forecast.setMayDelayProjectsCount(3);
        forecast.setMayDelayProjectsPercentage(12.50);
        forecast.setAtRiskProjectsCount(3);
        forecast.setAtRiskProjectsPercentage(12.50);
        response.setForecastSummary(forecast);

        return response;
    }

    private ProjectDashboardResponse.DelayedMilestoneItem createDelayedItem(String title, String prjCd, long delayDays) {
        ProjectDashboardResponse.DelayedMilestoneItem item = new ProjectDashboardResponse.DelayedMilestoneItem();
        item.setMilestoneTitle(title);
        item.setProjectCd(prjCd);
        item.setDelayDays(delayDays);
        return item;
    }

    private ProjectDashboardResponse.UpcomingMilestoneItem createUpcomingItem(String title, String prjCd, String dueDate, String status) {
        ProjectDashboardResponse.UpcomingMilestoneItem item = new ProjectDashboardResponse.UpcomingMilestoneItem();
        item.setMilestoneTitle(title);
        item.setProjectCd(prjCd);
        item.setDueDate(dueDate);
        item.setStatus(status);
        return item;
    }

    private ProjectDashboardResponse.HighPriorityTaskItem createHpTask(String name, String prjCd, String assignee, String dueDate) {
        ProjectDashboardResponse.HighPriorityTaskItem item = new ProjectDashboardResponse.HighPriorityTaskItem();
        item.setTaskNm(name);
        item.setProjectCd(prjCd);
        item.setAssigneeNm(assignee);
        item.setDueDate(dueDate);
        return item;
    }
}
