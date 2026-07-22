package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.entity.TaskStatusMaster;
import com.bionova.entity.ScreenMaster;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.RoleBasedEmployeeMappingRepository;
import com.bionova.repository.RoleBasedAccessControlRepository;
import com.bionova.repository.ScreenMasterRepository;
import com.bionova.service.ProjectPromotionService;
import com.bionova.service.ActivityLogService;
import com.bionova.service.ProjectLeadLagService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/project-live")
public class ProjectLiveController {

    @Autowired private ProjectLiveRepository            projectLiveRepository;
    @Autowired private MilestoneLiveRepository          milestoneLiveRepository;
    @Autowired private TaskLiveRepository               taskLiveRepository;
    @Autowired private ProjectPromotionService          promotionService;
    @Autowired private EmployeeRepository               employeeRepository;
    @Autowired private ActivityLogService               activityLogService;
    @Autowired private RoleBasedEmployeeMappingRepository rbacMappingRepository;
    @Autowired private ProjectLeadLagService            leadLagService;
    @Autowired private com.bionova.repository.ChecklistMasterRepository checklistMasterRepository;
    @Autowired private com.bionova.repository.AttachmentMasterRepository attachmentMasterRepository;
    @Autowired private com.bionova.repository.ProcessConfigRepository processConfigRepository;
    @Autowired private com.bionova.service.ProjectStatusCascadeService projectStatusCascadeService;
    @Autowired private RoleBasedAccessControlRepository rbacRepository;
    @Autowired private ScreenMasterRepository screenMasterRepository;
    @Autowired private com.bionova.repository.ProjectAccessRepository projectAccessRepository;
    @Autowired private com.bionova.repository.PlantRepository plantRepository;
    @Autowired private com.bionova.repository.CompanyRepository companyRepository;

    /**
     * Determines if the employee has access to the Project module.
     * Rules:
     *  - No RBAC mapping configured yet (full_access mode) -> true
     *  - Admin, Manager, PM, or full_access role -> true
     *  - Mapped role has view_flg = true for any screen in the "Project" group -> true
     */
    private void enrichProject(ProjectLive prj) {
        if (prj == null) return;
        
        String clientName = "";
        String location = "";
        if (prj.getCoyId() != null) {
            var coy = companyRepository.findById(prj.getCoyId().longValue()).orElse(null);
            if (coy != null) {
                clientName = coy.getCoyNm();
                location = coy.getCtVlg();
            }
        }
        if (clientName == null || clientName.isEmpty()) {
            List<com.bionova.entity.CompanyMaster> allCompanies = companyRepository.findAll();
            if (!allCompanies.isEmpty()) {
                clientName = allCompanies.get(0).getCoyNm();
                location = allCompanies.get(0).getCtVlg();
            } else {
                clientName = "";
                location = "";
            }
        }
        prj.setClientName(clientName);

        String plantName = "";
        if (prj.getPltId() != null) {
            var plt = plantRepository.findById(prj.getPltId().longValue()).orElse(null);
            if (plt != null) {
                plantName = plt.getPltNm();
            }
        }
        if (plantName == null || plantName.isEmpty()) {
            List<com.bionova.entity.PlantMaster> allPlants = plantRepository.findAll();
            if (!allPlants.isEmpty()) {
                plantName = allPlants.get(0).getPltNm();
            } else {
                plantName = "";
            }
        }
        prj.setPlantName(plantName);
        prj.setLocation(location);

        // Compute overall progress using all tasks across all milestones of the project
        List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(prj.getPrjId());
        double totalWeight = 0.0;
        double completedWeight = 0.0;
        for (MilestoneLive ms : milestones) {
            List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(ms.getMId());
            for (TaskLive t : tasks) {
                double weight = t.getWrkDays() != null && t.getWrkDays() > 0
                        ? t.getWrkDays()
                        : (t.getNoOfDays() != null && t.getNoOfDays() > 0 ? t.getNoOfDays() : 1.0);

                String sts = t.getTaskSts() != null ? t.getTaskSts().getStatusNm() : "Open";
                String subSts = t.getSubStatus() != null ? t.getSubStatus() : "";
                double taskPct = 0.0;
                if ("Closed".equalsIgnoreCase(sts)) {
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
                totalWeight += weight;
                completedWeight += (taskPct / 100.0) * weight;
            }
        }
        int progressPct = 0;
        if (totalWeight > 0) {
            progressPct = (int) Math.round((completedWeight / totalWeight) * 100.0);
        }
        prj.setProgress(progressPct);
    }

    private void enrichProjects(List<ProjectLive> projects) {
        if (projects == null) return;
        for (ProjectLive prj : projects) {
            enrichProject(prj);
        }
    }

    private boolean hasProjectModuleAccess(Employee employee) {
        if (employee == null) return false;
        
        var mappings = rbacMappingRepository.findByEmpId(employee.getEmpId());
        if (mappings.isEmpty()) {
            return true;
        }
        
        for (var mapping : mappings) {
            var rbacs = rbacRepository.findByRoleId(mapping.getRoleId());
            if (!rbacs.isEmpty()) {
                String roleNm = rbacs.get(0).getRoleNm();
                if (roleNm != null) {
                    String lowerRole = roleNm.toLowerCase();
                    if (lowerRole.contains("admin") || lowerRole.contains("manager") || lowerRole.contains("pm") || lowerRole.contains("full_access")) {
                        return true;
                    }
                }
            }
        }
        
        List<ScreenMaster> screens = screenMasterRepository.findAll();
        Set<Integer> projectScreenIds = new java.util.HashSet<>();
        for (ScreenMaster sm : screens) {
            if ("Project".equalsIgnoreCase(sm.getGroupNm())) {
                projectScreenIds.add(sm.getScreenId());
            }
        }
        
        for (var mapping : mappings) {
            var rbacs = rbacRepository.findByRoleId(mapping.getRoleId());
            for (var rbac : rbacs) {
                if (projectScreenIds.contains(rbac.getScreenId()) && Boolean.TRUE.equals(rbac.getViewFlg())) {
                    return true;
                }
            }
        }
        
        return false;
    }

    // ── GET ────────────────────────────────────────────────────────────────

    @GetMapping
    public List<ProjectLive> getAll() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        List<ProjectLive> list = employeeRepository.findByEmail(email)
                .map(employee -> {
                    if (hasProjectModuleAccess(employee)) {
                        return projectLiveRepository.findAll();
                    } else {
                        List<ProjectLive> projects = projectLiveRepository.findProjectsByEmpId(employee.getEmpId());
                        List<ProjectLive> accessedProjects = projectAccessRepository.findProjectsByEmpId(employee.getEmpId());
                        Set<ProjectLive> allProjects = new java.util.LinkedHashSet<>(projects);
                        allProjects.addAll(accessedProjects);
                        return new java.util.ArrayList<>(allProjects);
                    }
                })
                .orElse(List.of());
        enrichProjects(list);
        return list;
    }

    @GetMapping("/by-employee/{empId}")
    public ResponseEntity<?> getProjectsByEmployee(@PathVariable Long empId) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);
        if (employee == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Unauthorized"));
        }

        if (hasProjectModuleAccess(employee) || 
            employee.getEmpId().equals(empId)) {
            List<ProjectLive> list = projectLiveRepository.findProjectsByEmpId(empId);
            enrichProjects(list);
            return ResponseEntity.ok(list);
        } else {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ProjectLive> getById(@PathVariable Long id) {
        return projectLiveRepository.findById(id)
                .map(prj -> {
                    enrichProject(prj);
                    return ResponseEntity.ok(prj);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{id}/milestones")
    public List<MilestoneLive> getMilestones(@PathVariable Long id) {
        return milestoneLiveRepository.findByPrjId(id);
    }

    private void populateReviewerAndApprover(TaskLive task) {
        if (task == null) return;
        List<com.bionova.entity.ProcessConfig> configs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(task.getTaskId(), true);
        for (com.bionova.entity.ProcessConfig pc : configs) {
            if (pc.getOrdrId() == 1) {
                task.setReviewer(pc.getEmpId());
            } else if (pc.getOrdrId() == 2) {
                task.setApprover(pc.getEmpId());
            }
        }
    }

    private void populateReviewerAndApprover(List<TaskLive> tasks) {
        if (tasks == null) return;
        for (TaskLive task : tasks) {
            populateReviewerAndApprover(task);
        }
    }

    @GetMapping("/milestones/{mId}/tasks")
    public List<TaskLive> getTasks(@PathVariable Long mId) {
        List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(mId);
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    // ── Lead / Lag / On Time ───────────────────────────────────────────────

    /**
     * GET /api/project-live/{id}/lead-lag-status
     * Full Lead/Lag detail for a single project:
     *   - expectedProgress, actualProgress, variance
     *   - leadLagStatus (LEAD / ON_TIME / LAG)
     *   - daysVariance, leadLagColor, leadLagLabel
     */
    @GetMapping("/{id}/lead-lag-status")
    public ResponseEntity<?> getLeadLagStatus(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(leadLagService.getLeadLagDetail(id));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * GET /api/project-live/lead-lag-summary
     * Summary across ALL live projects:
     *   - leadCount, onTimeCount, lagCount, totalLive
     *   - projects[]: per-project compact status rows
     * Used by Project Dashboard overview cards.
     */
    @GetMapping("/lead-lag-summary")
    public ResponseEntity<?> getLeadLagSummary() {
        return ResponseEntity.ok(leadLagService.getAllProjectsLeadLagSummary());
    }

    /**
     * GET /api/project-live/check-ready/{drftPrjId}
     *
     * Pre-flight check before promoting a draft to Live.
     * Returns:
     *   { "ready": true }                         -- safe to promote
     *   { "ready": false, "warnings": [...] }     -- show warnings to user
     */
    @GetMapping("/check-ready/{drftPrjId}")
    public ResponseEntity<?> checkReady(@PathVariable Long drftPrjId) {
        java.util.List<String> warnings = new java.util.ArrayList<>();

        // Already live?
        if (promotionService.isAlreadyLive(drftPrjId)) {
            warnings.add("This project has already been promoted to Live.");
            return ResponseEntity.ok(java.util.Map.of("ready", false, "warnings", warnings));
        }

        // Count milestones
        long milestoneCount = promotionService.countMilestones(drftPrjId);
        if (milestoneCount == 0) {
            warnings.add("No milestones found. Please add at least one milestone before going live.");
        }

        // Count tasks (only meaningful if milestones exist)
        if (milestoneCount > 0) {
            long taskCount = promotionService.countTasks(drftPrjId);
            if (taskCount == 0) {
                warnings.add("No tasks found. Please add at least one task to a milestone before going live.");
            }
        }

        boolean ready = warnings.isEmpty();
        java.util.Map<String, Object> response = new java.util.LinkedHashMap<>();
        response.put("ready", ready);
        if (!ready) {
            response.put("warnings", warnings);
        }
        return ResponseEntity.ok(response);
    }

    // ── PROMOTE: Draft -> Live ─────────────────────────────────────────────

    /**
     * POST /api/project-live/promote/{drftPrjId}
     *
     * Body (JSON):
     * {
     *   "excludeSat": false,
     *   "excludeSun": true,
     *   "includeMandatory": true,
     *   "coyHolidays": true,
     *   "pltHolidays": true,
     *   "extHolidays": true
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
        boolean extHolidays      = getBool(options, "extHolidays",      false);

        try {
            Map<String, Object> result = promotionService.promoteToLive(
                    drftPrjId, excludeSat, excludeSun, includeMandatory, coyHolidays, pltHolidays, extHolidays);
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
        ProjectLive saved = projectLiveRepository.save(project);
        
        // Cascade the status to milestones and tasks
        projectStatusCascadeService.cascadeStatusFromProject(id, newStatus);
        
        return ResponseEntity.ok(saved);
    }

    /** PATCH /api/project-live/milestones/{mId}/status  Body: { "mlstnSts": "CLOSED" } */
    @PatchMapping("/milestones/{mId}/status")
    public ResponseEntity<?> updateMilestoneStatus(
            @PathVariable Long mId,
            @RequestBody Map<String, String> body) {

        MilestoneLive ms = milestoneLiveRepository.findById(mId)
                .orElseThrow(() -> new RuntimeException("Milestone not found: " + mId));

        String newStatus = body.get("mlstnSts");
        if (!List.of("LIVE", "HOLD", "CLOSED").contains(newStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: LIVE, HOLD, CLOSED"));
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
        if (newStatus == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "taskSts is required"));
        }
        String upperStatus = newStatus.toUpperCase().replace(" ", "_");
        if (!List.of("DRAFT","OPEN","WIP","UNDER_REVIEW","CLOSED","REASSIGN","REWORK","OVER_DUE","HOLD").contains(upperStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: DRAFT, OPEN, WIP, UNDER_REVIEW, CLOSED, REASSIGN, REWORK, OVER_DUE, HOLD"));
        }
        task.setTaskSts(TaskStatusMaster.getByName(newStatus));
        if ("UNDER_REVIEW".equals(upperStatus)) {
            task.setSubStatus("Under Review");
        } else if ("REWORK".equals(upperStatus)) {
            task.setSubStatus("Rework");
        } else if ("REASSIGN".equals(upperStatus)) {
            task.setSubStatus("Reassign");
        } else if ("OVER_DUE".equals(upperStatus) || "OVERDUE".equals(upperStatus)) {
            task.setSubStatus("Overdue");
        } else {
            task.setSubStatus(null);
        }
        TaskLive saved = taskLiveRepository.save(task);
        projectStatusCascadeService.cascadeStatusFromTask(taskId);
        return ResponseEntity.ok(saved);
    }

    /** DELETE /api/project-live/{id} */
    @DeleteMapping("/{id}")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        List<com.bionova.entity.MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(id);
        for (com.bionova.entity.MilestoneLive milestone : milestones) {
            List<com.bionova.entity.TaskLive> tasks = taskLiveRepository.findByMilestoneId(milestone.getMId());
            for (com.bionova.entity.TaskLive task : tasks) {
                // Delete task checklists
                List<com.bionova.entity.ChecklistMaster> checklists = checklistMasterRepository.findByTaskIdAndIsLive(task.getTaskId(), true);
                checklistMasterRepository.deleteAll(checklists);

                // Delete task attachments
                List<com.bionova.entity.AttachmentMaster> attachments = attachmentMasterRepository.findByTIdAndIsLive(task.getTaskId(), true);
                attachmentMasterRepository.deleteAll(attachments);

                // Delete task process configs
                List<com.bionova.entity.ProcessConfig> processConfigs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(task.getTaskId(), true);
                processConfigRepository.deleteAll(processConfigs);

                // Delete task
                taskLiveRepository.delete(task);
            }
            // Delete milestone
            milestoneLiveRepository.delete(milestone);
        }
        // Delete project itself
        projectLiveRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // ── helper ─────────────────────────────────────────────────────────────
    private boolean getBool(Map<String, Object> map, String key, boolean defaultVal) {
        Object val = map.get(key);
        if (val instanceof Boolean b) return b;
        if (val instanceof String s) return Boolean.parseBoolean(s);
        return defaultVal;
    }
}
