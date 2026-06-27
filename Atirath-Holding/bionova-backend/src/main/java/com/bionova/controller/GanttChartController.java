package com.bionova.controller;

import com.bionova.dto.GanttTaskDto;
import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.ProjectDraftRepository;
import com.bionova.repository.MilestoneDraftRepository;
import com.bionova.repository.TaskDraftRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/gantt")
public class GanttChartController {

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private ProjectDraftRepository projectDraftRepository;

    @Autowired
    private MilestoneDraftRepository milestoneDraftRepository;

    @Autowired
    private TaskDraftRepository taskDraftRepository;

    /**
     * Get list of all projects to populate project selector for Gantt view
     */
    @GetMapping("/projects")
    public ResponseEntity<List<Map<String, Object>>> getProjectsForGantt() {
        List<ProjectLive> projects = projectLiveRepository.findAll();
        List<Map<String, Object>> result = projects.stream().map(p -> {
            Map<String, Object> map = new HashMap<>();
            map.put("prjId", p.getPrjId());
            map.put("prjCd", p.getPrjCd());
            map.put("prjNm", p.getPrjNm());
            map.put("prjSts", p.getPrjSts());
            return map;
        }).collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    /**
     * Get flat list of Gantt items (Project, Milestones, Tasks) for a project
     */
    @GetMapping("/{projectId}")
    public ResponseEntity<?> getGanttData(@PathVariable Long projectId) {
        ProjectLive project = projectLiveRepository.findById(projectId).orElse(null);
        if (project == null) {
            return ResponseEntity.notFound().build();
        }

        List<GanttTaskDto> ganttTasks = new ArrayList<>();

        // 1. Fetch Milestones
        List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(projectId);

        // Fetch all employees in a map for quick lookup
        Map<Long, String> employeeNameMap = employeeRepository.findAll().stream()
                .collect(Collectors.toMap(
                        Employee::getEmpId,
                        e -> e.getFirstName() + " " + (e.getLastName() != null ? e.getLastName() : ""),
                        (v1, v2) -> v1 // In case of duplicate keys
                ));

        // 2. Fetch Tasks for all these milestones and group them by milestone ID
        Map<Long, List<TaskLive>> tasksByMilestone = new HashMap<>();
        for (MilestoneLive ms : milestones) {
            List<TaskLive> msTasks = taskLiveRepository.findByMilestoneId(ms.getMId());
            tasksByMilestone.put(ms.getMId(), msTasks);
        }

        // 3. Compute progress for Project
        double projectProgress = 0.0;
        int totalMilestones = milestones.size();
        double totalMilestoneProgressSum = 0.0;

        List<GanttTaskDto> milestoneDtos = new ArrayList<>();

        for (MilestoneLive ms : milestones) {
            List<TaskLive> msTasks = tasksByMilestone.getOrDefault(ms.getMId(), new ArrayList<>());

            // Compute Milestone Progress
            double milestoneProgress = 0.0;
            if ("COMPLETED".equalsIgnoreCase(ms.getMlstnSts()) || "CLOSED".equalsIgnoreCase(ms.getMlstnSts())) {
                milestoneProgress = 1.0;
            } else if (!msTasks.isEmpty()) {
                double taskProgressSum = 0.0;
                for (TaskLive task : msTasks) {
                    taskProgressSum += getTaskProgressValue(task.getTaskSts());
                }
                milestoneProgress = taskProgressSum / msTasks.size();
            }
            totalMilestoneProgressSum += milestoneProgress;

            // Fetch Milestone Baseline Dates (from draft milestone if available)
            final List<LocalDate> msDates = new ArrayList<>();
            msDates.add(ms.getStDt());
            msDates.add(ms.getEndDt());
            if (ms.getDrftMId() != null) {
                milestoneDraftRepository.findById(ms.getDrftMId()).ifPresent(drft -> {
                    msDates.set(0, drft.getTentStDt());
                    msDates.set(1, drft.getTentEndDt());
                });
            }

            // Create Milestone Gantt Item
            GanttTaskDto msDto = new GanttTaskDto(
                    "MS-" + ms.getMId(),
                    ms.getMlstnTtl(),
                    "milestone",
                    ms.getStDt(),
                    ms.getEndDt(),
                    milestoneProgress,
                    "PRJ-" + project.getPrjId(),
                    ms.getMlstnSts(),
                    ms.getMlstnCd(),
                    null,
                    ms.getMlstnDepMId() != null ? "MS-" + ms.getMlstnDepMId() : null,
                    msDates.get(0),
                    msDates.get(1)
            );
            milestoneDtos.add(msDto);

            // Create Task Gantt Items
            for (TaskLive task : msTasks) {
                double taskProgress = getTaskProgressValue(task.getTaskSts());
                String assigneeName = task.getEmpId() != null ? employeeNameMap.get(task.getEmpId()) : null;

                // Fetch Task Baseline Dates (from draft task if available)
                final List<LocalDate> taskDates = new ArrayList<>();
                taskDates.add(task.getStDt());
                taskDates.add(task.getEndDt());
                if (task.getDrftTaskId() != null) {
                    taskDraftRepository.findById(task.getDrftTaskId()).ifPresent(drft -> {
                        taskDates.set(0, drft.getTentStDt());
                        taskDates.set(1, drft.getTentEndDt());
                    });
                }

                GanttTaskDto taskDto = new GanttTaskDto(
                        "TSK-" + task.getTaskId(),
                        task.getTaskNm(),
                        "task",
                        task.getStDt(),
                        task.getEndDt(),
                        taskProgress,
                        "MS-" + ms.getMId(),
                        task.getTaskSts(),
                        task.getTaskCd(),
                        assigneeName,
                        task.getDepTaskId() != null ? "TSK-" + task.getDepTaskId() : null,
                        taskDates.get(0),
                        taskDates.get(1)
                );
                ganttTasks.add(taskDto);
            }
        }

        // Finalize Project Progress
        if ("CLOSED".equalsIgnoreCase(project.getPrjSts())) {
            projectProgress = 1.0;
        } else if (totalMilestones > 0) {
            projectProgress = totalMilestoneProgressSum / totalMilestones;
        }

        // Fetch Project Baseline Dates (from draft project if available)
        final List<LocalDate> prjDates = new ArrayList<>();
        prjDates.add(project.getStDt());
        prjDates.add(project.getEndDt());
        if (project.getDrftPrjId() != null) {
            projectDraftRepository.findById(project.getDrftPrjId()).ifPresent(drft -> {
                prjDates.set(0, drft.getTentStDt());
                prjDates.set(1, drft.getTentEndDt());
            });
        }

        // Add Project Gantt Item at the top
        GanttTaskDto prjDto = new GanttTaskDto(
                "PRJ-" + project.getPrjId(),
                project.getPrjNm(),
                "project",
                project.getStDt(),
                project.getEndDt(),
                projectProgress,
                null,
                project.getPrjSts(),
                project.getPrjCd(),
                null,
                null,
                prjDates.get(0),
                prjDates.get(1)
        );

        // Assemble the list: Project first, then Milestones & Tasks
        List<GanttTaskDto> finalData = new ArrayList<>();
        finalData.add(prjDto);
        finalData.addAll(milestoneDtos);
        finalData.addAll(ganttTasks);

        return ResponseEntity.ok(finalData);
    }

    private double getTaskProgressValue(String status) {
        if (status == null) return 0.0;
        switch (status.toUpperCase()) {
            case "COMPLETED":
                return 1.0;
            case "SUBMIT_REVIEW":
            case "UNDER_REVIEW":
                return 0.8;
            case "WIP":
                return 0.5;
            case "OPEN":
            case "REWORK":
            default:
                return 0.0;
        }
    }
}
