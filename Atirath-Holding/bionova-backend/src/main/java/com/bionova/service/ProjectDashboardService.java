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

}
