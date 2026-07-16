package com.bionova.service;

import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Calculates Lead / On Time / Lag status for live projects.
 *
 * Logic:
 *   expectedProgress = (daysElapsed / totalProjectDays) × 100
 *   actualProgress   = Σ(task weight × task % done) / Σ(task weight) × 100
 *
 *   variance = actualProgress - expectedProgress
 *
 *   LEAD    → variance > +5%  (ahead of schedule)
 *   ON_TIME → variance within ±5%
 *   LAG     → variance < -5%  OR today > endDate and not fully done
 *
 * On full completion:
 *   LEAD    → actCmpDt < endDt
 *   ON_TIME → actCmpDt == endDt
 *   LAG     → actCmpDt > endDt
 */
@Service
public class ProjectLeadLagService {

    // Tolerance band: within ±5% variance = ON_TIME
    private static final double TOLERANCE_PERCENT = 5.0;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    // ──────────────────────────────────────────────────────────────────────────
    // Public API
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Returns Lead/Lag detail for a single project.
     * Includes all metrics needed for the Project Dashboard card.
     */
    public Map<String, Object> getLeadLagDetail(Long prjId) {
        ProjectLive project = projectLiveRepository.findById(prjId)
                .orElseThrow(() -> new RuntimeException("Project not found: " + prjId));

        List<TaskLive> allTasks = getAllTasksForProject(prjId);
        return buildDetail(project, allTasks, LocalDate.now());
    }

    /**
     * Returns Lead/Lag summary for ALL live projects.
     * Used by Project Dashboard overview.
     */
    public Map<String, Object> getAllProjectsLeadLagSummary() {
        List<ProjectLive> allProjects = projectLiveRepository.findAll();
        LocalDate today = LocalDate.now();

        int leadCount   = 0;
        int onTimeCount = 0;
        int lagCount    = 0;

        List<Map<String, Object>> projectList = new ArrayList<>();

        for (ProjectLive project : allProjects) {
            if (!"LIVE".equals(project.getPrjSts()) && !"CLOSED".equals(project.getPrjSts())) {
                continue; // skip HOLD etc.
            }
            List<TaskLive> tasks = getAllTasksForProject(project.getPrjId());
            Map<String, Object> detail = buildDetail(project, tasks, today);

            String status = (String) detail.get("leadLagStatus");
            if ("LEAD".equals(status))    leadCount++;
            else if ("ON_TIME".equals(status)) onTimeCount++;
            else if ("LAG".equals(status))     lagCount++;

            // Compact row for list view
            Map<String, Object> row = new HashMap<>();
            row.put("projectId",    project.getPrjId());
            row.put("projectCode",  project.getPrjCd());
            row.put("projectName",  project.getPrjNm());
            row.put("projectStatus", project.getPrjSts());
            row.put("plannedEndDate", project.getEndDt() != null ? project.getEndDt().toString() : null);
            row.put("actualCompletionDate", project.getActCmpDt() != null ? project.getActCmpDt().toString() : null);
            row.put("leadLagStatus",   detail.get("leadLagStatus"));
            row.put("leadLagLabel",    detail.get("leadLagLabel"));
            row.put("leadLagColor",    detail.get("leadLagColor"));
            row.put("daysVariance",    detail.get("daysVariance"));
            row.put("actualProgress",  detail.get("actualProgress"));
            row.put("expectedProgress",detail.get("expectedProgress"));
            row.put("variance",        detail.get("variance"));
            projectList.add(row);
        }

        Map<String, Object> summary = new HashMap<>();
        summary.put("totalLive",  leadCount + onTimeCount + lagCount);
        summary.put("leadCount",  leadCount);
        summary.put("onTimeCount", onTimeCount);
        summary.put("lagCount",   lagCount);
        summary.put("projects",   projectList);
        return summary;
    }

    /**
     * Returns minimal Lead/Lag info for a specific employee's projects.
     * Used by User Dashboard.
     */
    public Map<String, Object> getLeadLagForEmployee(Long empId) {
        // Projects where the employee has tasks
        List<MilestoneLive> milestones = milestoneLiveRepository.findMilestonesByEmpId(empId);
        List<Long> prjIds = milestones.stream()
                .map(MilestoneLive::getPrjId)
                .distinct()
                .toList();

        LocalDate today = LocalDate.now();
        List<Map<String, Object>> projectRows = new ArrayList<>();

        for (Long prjId : prjIds) {
            ProjectLive project = projectLiveRepository.findById(prjId).orElse(null);
            if (project == null) continue;

            List<TaskLive> tasks = getAllTasksForProject(prjId);
            Map<String, Object> detail = buildDetail(project, tasks, today);

            Map<String, Object> row = new HashMap<>();
            row.put("projectId",    project.getPrjId());
            row.put("projectCode",  project.getPrjCd());
            row.put("projectName",  project.getPrjNm());
            row.put("leadLagStatus", detail.get("leadLagStatus"));
            row.put("leadLagLabel",  detail.get("leadLagLabel"));
            row.put("leadLagColor",  detail.get("leadLagColor"));
            row.put("daysVariance",  detail.get("daysVariance"));
            row.put("actualProgress",detail.get("actualProgress"));
            projectRows.add(row);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("projects", projectRows);
        return result;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Core calculation — called by CascadeService after task update too
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Recalculates and PERSISTS lead_lag_sts (and actCmpDt if all done) for a project.
     * Called by ProjectStatusCascadeService whenever a task status changes.
     */
    @Transactional
    public void recalculateAndPersist(Long prjId) {
        ProjectLive project = projectLiveRepository.findById(prjId).orElse(null);
        if (project == null) return;

        List<TaskLive> allTasks = getAllTasksForProject(prjId);

        // Check if all tasks are completed
        boolean allDone = !allTasks.isEmpty()
                && allTasks.stream().allMatch(t ->
                "COMPLETED".equalsIgnoreCase(
                        t.getTaskSts() != null ? t.getTaskSts().getStatusNm() : ""));

        LocalDate today = LocalDate.now();

        if (allDone && project.getActCmpDt() == null) {
            project.setActCmpDt(today);
        }

        String status = computeStatus(project, allTasks, today);
        project.setLeadLagSts(status);
        projectLiveRepository.save(project);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ──────────────────────────────────────────────────────────────────────────

    /**
     * Builds a full detail map for the API response.
     */
    private Map<String, Object> buildDetail(ProjectLive project, List<TaskLive> allTasks, LocalDate today) {
        LocalDate startDate = project.getStDt();
        LocalDate endDate   = project.getEndDt();
        LocalDate actCmpDt  = project.getActCmpDt();

        // Guard
        if (startDate == null) startDate = today;
        if (endDate == null)   endDate   = today.plusDays(1);

        // ── Expected progress (time-based) ──────────────────────────────────
        long totalDays   = Math.max(endDate.toEpochDay() - startDate.toEpochDay(), 1);
        long elapsedDays = Math.min(
                Math.max(today.toEpochDay() - startDate.toEpochDay(), 0),
                totalDays);
        double expectedProgress = (elapsedDays * 100.0) / totalDays;

        // ── Actual progress (task-weight based) ─────────────────────────────
        double actualProgress = computeActualProgress(allTasks);

        // ── Variance ────────────────────────────────────────────────────────
        double variance = actualProgress - expectedProgress;

        // ── Status string ────────────────────────────────────────────────────
        String status;
        int daysVariance = 0;

        if (actCmpDt != null) {
            // Project fully completed — compare actual vs planned end date
            long diff = actCmpDt.toEpochDay() - endDate.toEpochDay();
            // diff < 0 means completed before endDate (LEAD)
            daysVariance = (int) -diff;
            if (diff < 0)       status = "LEAD";
            else if (diff == 0) status = "ON_TIME";
            else                status = "LAG";
        } else {
            // Still in progress
            status = null;
            daysVariance = 0;
        }

        // ── Label + color ─────────────────────────────────────────────────
        String label = null, color = null;
        if (status != null) {
            switch (status) {
                case "LEAD"    -> { label = "Lead";    color = "#10b981"; } // green
                case "LAG"     -> { label = "Lag";     color = "#ef4444"; } // red
                default        -> { label = "On Time"; color = "#f59e0b"; } // amber
            }
        }

        // ── Build response ─────────────────────────────────────────────────
        Map<String, Object> detail = new HashMap<>();
        detail.put("projectId",             project.getPrjId());
        detail.put("projectCode",           project.getPrjCd());
        detail.put("projectName",           project.getPrjNm());
        detail.put("projectStatus",         project.getPrjSts());
        detail.put("startDate",             startDate.toString());
        detail.put("plannedEndDate",        endDate.toString());
        detail.put("actualCompletionDate",  actCmpDt != null ? actCmpDt.toString() : null);
        detail.put("todayDate",             today.toString());
        detail.put("totalDays",             totalDays);
        detail.put("elapsedDays",           elapsedDays);
        detail.put("expectedProgress",      round2(expectedProgress));
        detail.put("actualProgress",        round2(actualProgress));
        detail.put("variance",              round2(variance));
        detail.put("leadLagStatus",         status);
        detail.put("leadLagLabel",          label);
        detail.put("leadLagColor",          color);
        detail.put("daysVariance",          daysVariance);
        detail.put("totalTasks",            allTasks.size());
        detail.put("completedTasks",
                allTasks.stream().filter(t ->
                        "COMPLETED".equalsIgnoreCase(
                                t.getTaskSts() != null ? t.getTaskSts().getStatusNm() : ""))
                        .count());
        return detail;
    }

    /**
     * Lightweight status computation (no map building) — used by persist path.
     */
    private String computeStatus(ProjectLive project, List<TaskLive> allTasks, LocalDate today) {
        LocalDate endDate   = project.getEndDt();
        LocalDate actCmpDt  = project.getActCmpDt();

        if (endDate == null) endDate   = today.plusDays(1);

        if (actCmpDt != null) {
            long diff = actCmpDt.toEpochDay() - endDate.toEpochDay();
            if (diff < 0)      return "LEAD";
            else if (diff == 0) return "ON_TIME";
            else                return "LAG";
        }

        return null;
    }

    /**
     * Weighted actual progress across all tasks.
     * Weight = wrkDays (else noOfDays, else 1).
     * Task progress: COMPLETED=100%, UNDER_REVIEW/SUBMIT_REVIEW=80%,
     *               WIP=50%, REWORK=20%, OPEN=0%.
     */
    private double computeActualProgress(List<TaskLive> tasks) {
        if (tasks == null || tasks.isEmpty()) return 0.0;

        double totalWeight     = 0.0;
        double completedWeight = 0.0;

        for (TaskLive t : tasks) {
            double weight = t.getWrkDays() != null && t.getWrkDays() > 0
                    ? t.getWrkDays()
                    : (t.getNoOfDays() != null && t.getNoOfDays() > 0 ? t.getNoOfDays() : 1.0);

            String sts = t.getTaskSts() != null ? t.getTaskSts().getStatusNm() : "Open";
            String subSts = t.getSubStatus() != null ? t.getSubStatus() : "";
            double taskPct = 0.0;
            if ("Completed".equalsIgnoreCase(sts)) {
                taskPct = 100.0;
            } else if ("WIP".equalsIgnoreCase(sts)) {
                if ("Under Review".equalsIgnoreCase(subSts)) {
                    taskPct = 80.0;
                } else if ("Rework".equalsIgnoreCase(subSts)) {
                    taskPct = 20.0;
                } else {
                    taskPct = 50.0;
                }
            }

            totalWeight     += weight;
            completedWeight += (taskPct / 100.0) * weight;
        }

        return totalWeight > 0 ? (completedWeight / totalWeight) * 100.0 : 0.0;
    }

    /**
     * Loads all tasks across all milestones of a project in one pass.
     */
    private List<TaskLive> getAllTasksForProject(Long prjId) {
        List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(prjId);
        List<TaskLive> tasks = new ArrayList<>();
        for (MilestoneLive ms : milestones) {
            tasks.addAll(taskLiveRepository.findByMilestoneId(ms.getMId()));
        }
        return tasks;
    }

    private double round2(double val) {
        return Math.round(val * 100.0) / 100.0;
    }
}
