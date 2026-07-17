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
     * Get Gantt data for ALL live projects (Project → Milestones → Tasks for each).
     * Use this endpoint to render a cross-project Gantt chart.
     */
    @GetMapping("/all")
    public ResponseEntity<List<GanttTaskDto>> getAllProjectsGanttData() {
        List<ProjectLive> allProjects = projectLiveRepository.findAll();
        List<GanttTaskDto> result = new ArrayList<>();
        for (ProjectLive project : allProjects) {
            result.addAll(buildGanttForProject(project));
        }
        return ResponseEntity.ok(result);
    }

    /**
     * Get flat list of Gantt items (Project, Milestones, Tasks) for a single project.
     */
    @GetMapping("/{projectId}")
    public ResponseEntity<?> getGanttData(@PathVariable Long projectId) {
        ProjectLive project = projectLiveRepository.findById(projectId).orElse(null);
        if (project == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(buildGanttForProject(project));
    }

    /**
     * Shared helper: builds a flat list of GanttTaskDto rows for a given project.
     * Order: Project row first, then its Milestones, then Tasks under each Milestone.
     */
    private List<GanttTaskDto> buildGanttForProject(ProjectLive project) {

        // 1. Fetch Milestones for this project
        List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(project.getPrjId());

        // 2. Fetch & group Tasks; collect employee IDs
        Map<Long, List<TaskLive>> tasksByMilestone = new HashMap<>();
        java.util.Set<Long> empIds = new java.util.HashSet<>();
        for (MilestoneLive ms : milestones) {
            List<TaskLive> msTasks = taskLiveRepository.findByMilestoneId(ms.getMId());
            tasksByMilestone.put(ms.getMId(), msTasks);
            for (TaskLive t : msTasks) {
                if (t.getEmpId() != null)    empIds.add(t.getEmpId());
                if (t.getExtEmpId() != null) empIds.add(t.getExtEmpId());
            }
        }

        // 3. Resolve employee names
        Map<Long, String> employeeNameMap = new HashMap<>();
        if (!empIds.isEmpty()) {
            employeeRepository.findAllById(empIds).forEach(e ->
                employeeNameMap.put(e.getEmpId(),
                    e.getFirstName() + " " + (e.getLastName() != null ? e.getLastName() : ""))
            );
        }

        // 4. Build Milestone + Task rows, accumulate progress
        double totalMilestoneProgressSum = 0.0;
        List<GanttTaskDto> milestoneDtos = new ArrayList<>();
        List<GanttTaskDto> taskDtos      = new ArrayList<>();

        for (MilestoneLive ms : milestones) {
            List<TaskLive> msTasks = tasksByMilestone.getOrDefault(ms.getMId(), new ArrayList<>());

            // Milestone progress
            double milestoneProgress = 0.0;
            if ("COMPLETED".equalsIgnoreCase(ms.getMlstnSts()) || "CLOSED".equalsIgnoreCase(ms.getMlstnSts())) {
                milestoneProgress = 1.0;
            } else if (!msTasks.isEmpty()) {
                double taskProgressSum = 0.0;
                for (TaskLive task : msTasks) taskProgressSum += getTaskProgressValue(task);
                milestoneProgress = taskProgressSum / msTasks.size();
            }
            totalMilestoneProgressSum += milestoneProgress;

            // Milestone baseline dates
            final List<LocalDate> msDates = new ArrayList<>();
            msDates.add(ms.getStDt());
            msDates.add(ms.getEndDt());
            if (ms.getDrftMId() != null) {
                milestoneDraftRepository.findById(ms.getDrftMId()).ifPresent(drft -> {
                    msDates.set(0, drft.getTentStDt());
                    msDates.set(1, drft.getTentEndDt());
                });
            }

            milestoneDtos.add(new GanttTaskDto(
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
            ));

            // Task rows under this milestone
            for (TaskLive task : msTasks) {
                double taskProgress  = getTaskProgressValue(task);
                String assigneeName  = task.getEmpId() != null ? employeeNameMap.get(task.getEmpId()) : null;

                final List<LocalDate> taskDates = new ArrayList<>();
                taskDates.add(task.getStDt());
                taskDates.add(task.getEndDt());
                if (task.getDrftTaskId() != null) {
                    taskDraftRepository.findById(task.getDrftTaskId()).ifPresent(drft -> {
                        taskDates.set(0, drft.getTentStDt());
                        taskDates.set(1, drft.getTentEndDt());
                    });
                }

                taskDtos.add(new GanttTaskDto(
                        "TSK-" + task.getTaskId(),
                        task.getTaskNm(),
                        "task",
                        task.getStDt(),
                        task.getEndDt(),
                        taskProgress,
                        "MS-" + ms.getMId(),
                        task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "Open",
                        task.getTaskCd(),
                        assigneeName,
                        task.getDepTaskId() != null ? "TSK-" + task.getDepTaskId() : null,
                        taskDates.get(0),
                        taskDates.get(1)
                ));
            }
        }

        // 5. Compute overall project progress
        double projectProgress = 0.0;
        if ("CLOSED".equalsIgnoreCase(project.getPrjSts())) {
            projectProgress = 1.0;
        } else if (!milestones.isEmpty()) {
            projectProgress = totalMilestoneProgressSum / milestones.size();
        }

        // Project baseline dates
        final List<LocalDate> prjDates = new ArrayList<>();
        prjDates.add(project.getStDt());
        prjDates.add(project.getEndDt());
        if (project.getDrftPrjId() != null) {
            projectDraftRepository.findById(project.getDrftPrjId()).ifPresent(drft -> {
                prjDates.set(0, drft.getTentStDt());
                prjDates.set(1, drft.getTentEndDt());
            });
        }

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

        // 6. Assemble: Project → Milestones → Tasks
        List<GanttTaskDto> finalData = new ArrayList<>();
        finalData.add(prjDto);
        finalData.addAll(milestoneDtos);
        finalData.addAll(taskDtos);
        return finalData;
    }

    private double getTaskProgressValue(TaskLive task) {
        if (task == null || task.getTaskSts() == null) return 0.0;
        String status    = task.getTaskSts().getStatusNm();
        String subStatus = task.getSubStatus() != null ? task.getSubStatus() : "";
        if ("Completed".equalsIgnoreCase(status)) {
            return 1.0;
        } else if ("WIP".equalsIgnoreCase(status)) {
            if ("Under Review".equalsIgnoreCase(subStatus)) return 0.8;
            if ("Rework".equalsIgnoreCase(subStatus))       return 0.2;
            return 0.5;
        }
        return 0.0;
    }
}
