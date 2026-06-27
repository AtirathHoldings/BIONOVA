package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.service.ProjectPromotionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/project-live")
public class ProjectLiveController {

    @Autowired private ProjectLiveRepository   projectLiveRepository;
    @Autowired private MilestoneLiveRepository milestoneLiveRepository;
    @Autowired private TaskLiveRepository      taskLiveRepository;
    @Autowired private ProjectPromotionService promotionService;
    @Autowired private EmployeeRepository      employeeRepository;

    // ── GET ────────────────────────────────────────────────────────────────

    @GetMapping
    public List<ProjectLive> getAll() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> {
                    if ("admin".equalsIgnoreCase(employee.getRole()) || "manager".equalsIgnoreCase(employee.getRole())) {
                        return projectLiveRepository.findAll();
                    } else {
                        return projectLiveRepository.findProjectsByEmpId(employee.getEmpId());
                    }
                })
                .orElse(List.of());
    }

    @GetMapping("/by-employee/{empId}")
    public ResponseEntity<?> getProjectsByEmployee(@PathVariable Long empId) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);
        if (employee == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Unauthorized"));
        }

        if ("admin".equalsIgnoreCase(employee.getRole()) || 
            "manager".equalsIgnoreCase(employee.getRole()) || 
            employee.getEmpId().equals(empId)) {
            return ResponseEntity.ok(projectLiveRepository.findProjectsByEmpId(empId));
        } else {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProjectLive> getById(@PathVariable Long id) {
        return projectLiveRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/milestones")
    public List<MilestoneLive> getMilestones(@PathVariable Long id) {
        return milestoneLiveRepository.findByPrjId(id);
    }

    @GetMapping("/milestones/{mId}/tasks")
    public List<TaskLive> getTasks(@PathVariable Long mId) {
        return taskLiveRepository.findByMilestoneId(mId);
    }

    // ── PROMOTE: Draft → Live ──────────────────────────────────────────────

    /**
     * POST /api/project-live/promote/{drftPrjId}
     *
     * Body (JSON):
     * {
     *   "excludeSat": false,       -- exclude Saturdays
     *   "excludeSun": true,        -- exclude Sundays
     *   "includeMandatory": true,  -- include public/national holidays
     *   "coyHolidays": true,       -- include company-specific holidays
     *   "pltHolidays": true        -- include plant-specific holidays
     * }
     */
    @PostMapping("/promote/{drftPrjId}")
    public ResponseEntity<?> promote(
            @PathVariable Long drftPrjId,
            @RequestBody Map<String, Object> options) {

        boolean excludeSat       = getBool(options, "excludeSat",       false);
        boolean excludeSun       = getBool(options, "excludeSun",       true);
        boolean includeMandatory = getBool(options, "includeMandatory", true);
        boolean coyHolidays      = getBool(options, "coyHolidays",      true);
        boolean pltHolidays      = getBool(options, "pltHolidays",      true);

        try {
            Map<String, Object> result = promotionService.promoteToLive(
                    drftPrjId, excludeSat, excludeSun, includeMandatory, coyHolidays, pltHolidays);
            return ResponseEntity.ok(result);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    // ── Status update ──────────────────────────────────────────────────────

    /** PATCH /api/project-live/{id}/status  Body: { "prjSts": "HOLD" } */
    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {

        ProjectLive project = projectLiveRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Project not found: " + id));

        String newStatus = body.get("prjSts");
        if (!List.of("LIVE", "HOLD", "CLOSED").contains(newStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: LIVE, HOLD, CLOSED"));
        }
        project.setPrjSts(newStatus);
        return ResponseEntity.ok(projectLiveRepository.save(project));
    }

    /** PATCH /api/project-live/milestones/{mId}/status  Body: { "mlstnSts": "COMPLETED" } */
    @PatchMapping("/milestones/{mId}/status")
    public ResponseEntity<?> updateMilestoneStatus(
            @PathVariable Long mId,
            @RequestBody Map<String, String> body) {

        MilestoneLive ms = milestoneLiveRepository.findById(mId)
                .orElseThrow(() -> new RuntimeException("Milestone not found: " + mId));

        String newStatus = body.get("mlstnSts");
        if (!List.of("LIVE", "HOLD", "COMPLETED", "CLOSED").contains(newStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: LIVE, HOLD, COMPLETED, CLOSED"));
        }
        ms.setMlstnSts(newStatus);
        return ResponseEntity.ok(milestoneLiveRepository.save(ms));
    }

    /** PATCH /api/project-live/tasks/{taskId}/status  Body: { "taskSts": "WIP" } */
    @PatchMapping("/tasks/{taskId}/status")
    public ResponseEntity<?> updateTaskStatus(
            @PathVariable Long taskId,
            @RequestBody Map<String, String> body) {

        TaskLive task = taskLiveRepository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found: " + taskId));

        String newStatus = body.get("taskSts");
        if (!List.of("OPEN","WIP","SUBMIT_REVIEW","UNDER_REVIEW","COMPLETED","REWORK").contains(newStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: OPEN, WIP, SUBMIT_REVIEW, UNDER_REVIEW, COMPLETED, REWORK"));
        }
        task.setTaskSts(newStatus);
        return ResponseEntity.ok(taskLiveRepository.save(task));
    }

    // ── helper ─────────────────────────────────────────────────────────────
    private boolean getBool(Map<String, Object> map, String key, boolean defaultVal) {
        Object val = map.get(key);
        if (val instanceof Boolean b) return b;
        if (val instanceof String s) return Boolean.parseBoolean(s);
        return defaultVal;
    }
}
