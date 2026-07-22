package com.bionova.controller;

import com.bionova.dto.TeamMemberDto;
import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.entity.TeamMember;
import com.bionova.entity.TaskStatusMaster;
import com.bionova.entity.ScreenMaster;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.TeamMemberRepository;
import com.bionova.repository.RoleBasedEmployeeMappingRepository;
import com.bionova.repository.RoleBasedAccessControlRepository;
import com.bionova.repository.ScreenMasterRepository;
import com.bionova.repository.ProcessConfigRepository;
import com.bionova.service.ActivityLogService;
import com.bionova.service.ProjectStatusCascadeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/task-live")
public class TaskLiveController {

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private ActivityLogService activityLogService;

    @Autowired
    private ProjectStatusCascadeService projectStatusCascadeService;

    @Autowired
    private RoleBasedEmployeeMappingRepository rbacMappingRepository;

    @Autowired
    private RoleBasedAccessControlRepository rbacRepository;

    @Autowired
    private ScreenMasterRepository screenMasterRepository;

    @Autowired
    private ProcessConfigRepository processConfigRepository;

    @Autowired
    private TeamMemberRepository teamMemberRepository;

    /**
     * Determines if the employee has access to the Project module.
     * Rules:
     *  - No RBAC mapping configured yet (full_access mode) -> true
     *  - Admin, Manager, PM, or full_access role -> true
     *  - Mapped role has view_flg = true for any screen in the "Project" group -> true
     */
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

    private boolean isReviewerOrApproverForTask(Long taskId, Long empId) {
        List<com.bionova.entity.ProcessConfig> configs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(taskId, true);
        for (com.bionova.entity.ProcessConfig pc : configs) {
            if (empId.equals(pc.getEmpId())) {
                return true;
            }
        }
        return false;
    }

    private void populateReviewerAndApprover(TaskLive task) {
        if (task == null) return;
        List<com.bionova.entity.ProcessConfig> configs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(task.getTaskId(), true);
        for (com.bionova.entity.ProcessConfig pc : configs) {
            if (pc.getOrdrId() == 1) {
                task.setReviewer(pc.getEmpId());
                if (pc.getEmpId() != null) {
                    employeeRepository.findById(pc.getEmpId()).ifPresent(emp -> {
                        task.setReviewerNm(emp.getFirstName() + " " + emp.getLastName());
                    });
                }
            } else if (pc.getOrdrId() == 2) {
                task.setApprover(pc.getEmpId());
                if (pc.getEmpId() != null) {
                    employeeRepository.findById(pc.getEmpId()).ifPresent(emp -> {
                        task.setApproverNm(emp.getFirstName() + " " + emp.getLastName());
                    });
                }
            }
        }
    }

    private void populateReviewerAndApprover(List<TaskLive> tasks) {
        if (tasks == null) return;
        for (TaskLive task : tasks) {
            populateReviewerAndApprover(task);
        }
    }

    @GetMapping
    public List<TaskLive> getAll() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        List<TaskLive> tasks = employeeRepository.findByEmail(email)
                .map(employee -> {
                    if (hasProjectModuleAccess(employee)) {
                        return taskLiveRepository.findAll();
                    } else {
                        return taskLiveRepository.findTasksForEmployee(employee.getEmpId());
                    }
                })
                .orElse(List.of());
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);
        if (employee == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Unauthorized"));
        }

        return taskLiveRepository.findById(id)
                .map(task -> {
                    if (hasProjectModuleAccess(employee) || 
                        employee.getEmpId().equals(task.getEmpId()) ||
                        isReviewerOrApproverForTask(task.getTaskId(), employee.getEmpId())) {
                        populateReviewerAndApprover(task);
                        return ResponseEntity.ok(task);
                    } else {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied to this task"));
                    }
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-milestone/{mId}")
    public List<TaskLive> getByMilestone(@PathVariable Long mId) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        List<TaskLive> tasks = employeeRepository.findByEmail(email)
                .map(employee -> {
                    if (hasProjectModuleAccess(employee)) {
                        return taskLiveRepository.findByMilestoneId(mId);
                    } else {
                        return taskLiveRepository.findByMilestoneIdAndEmployeeOrReviewer(mId, employee.getEmpId());
                    }
                })
                .orElse(List.of());
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    @GetMapping("/by-employee/{empId}")
    public ResponseEntity<?> getByEmployee(@PathVariable Long empId) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);
        if (employee == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Unauthorized"));
        }

        if (hasProjectModuleAccess(employee) || 
            employee.getEmpId().equals(empId)) { 
            List<TaskLive> tasks = taskLiveRepository.findTasksForEmployee(empId);
            populateReviewerAndApprover(tasks);
            return ResponseEntity.ok(tasks);
        } else {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
        }
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody TaskLive task) {
        MilestoneLive milestone = milestoneLiveRepository.findById(task.getMId())
                .orElseThrow(() -> new RuntimeException("Milestone not found with ID: " + task.getMId()));

        if (task.getTaskCd() != null && !task.getTaskCd().trim().isEmpty()) {
            if (taskLiveRepository.existsByTaskCdAndProject(task.getTaskCd(), milestone.getPrjId())) {
                return ResponseEntity.badRequest().body(Map.of("message", "Task code already exists in this project."));
            }
        }

        if (task.getTaskSts() == null) {
            task.setTaskSts(TaskStatusMaster.OPEN);
        }

        // Auto-compute dates or days (inclusive: start=day1)
        if (task.getStDt() != null && task.getNoOfDays() != null) {
            task.setEndDt(task.getStDt().plusDays(task.getNoOfDays() - 1));
        } else if (task.getStDt() != null && task.getEndDt() != null) {
            long days = java.time.temporal.ChronoUnit.DAYS.between(task.getStDt(), task.getEndDt()) + 1;
            task.setNoOfDays((int) days);
        }

        TaskLive saved = taskLiveRepository.save(task);

        // Validate limits (Milestone & Project)
        String warning = null;
        if (saved.getStDt() != null && saved.getEndDt() != null) {
            boolean exceedsMilestone = saved.getStDt().isBefore(milestone.getStDt()) ||
                                       (milestone.getEndDt() != null && saved.getEndDt().isAfter(milestone.getEndDt())) ||
                                       (saved.getNoOfDays() != null && milestone.getWrkDays() != null && saved.getNoOfDays() > milestone.getWrkDays());

            boolean exceedsProject = false;
            ProjectLive project = projectLiveRepository.findById(milestone.getPrjId()).orElse(null);
            if (project != null) {
                exceedsProject = saved.getStDt().isBefore(project.getStDt()) ||
                                 (project.getEndDt() != null && saved.getEndDt().isAfter(project.getEndDt())) ||
                                 (saved.getNoOfDays() != null && project.getNoOfDays() != null && saved.getNoOfDays() > project.getNoOfDays());
            }

            if (exceedsMilestone || exceedsProject) {
                warning = "Warning: Task dates/days exceed milestone or project limits. You must also update the Milestone and Project dates/days accordingly.";
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("data", saved);
        if (warning != null) {
            response.put("warning", warning);
        }
        return ResponseEntity.ok(response);
    }

    @Transactional
    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody TaskLive details) {
        TaskLive task = taskLiveRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found: " + id));

        if (details.getTaskCd() != null && !details.getTaskCd().trim().isEmpty()) {
            Long mId = details.getMId() != null ? details.getMId() : task.getMId();
            MilestoneLive milestone = milestoneLiveRepository.findById(mId)
                    .orElseThrow(() -> new RuntimeException("Milestone not found: " + mId));
            if (taskLiveRepository.existsByTaskCdAndProjectAndTaskIdNot(details.getTaskCd(), milestone.getPrjId(), id)) {
                return ResponseEntity.badRequest().body(Map.of("message", "Task code already exists in this project."));
            }
            task.setTaskCd(details.getTaskCd());
        }

        task.setMId(details.getMId());
        task.setTaskNm(details.getTaskNm());
        task.setTaskDesc(details.getTaskDesc());
        task.setTaskAsgnTo(details.getTaskAsgnTo());
        task.setEmpId(details.getEmpId());
        task.setExtEmpId(details.getExtEmpId());
        task.setTaskDepFlg(details.getTaskDepFlg());
        task.setTaskDepTyp(details.getTaskDepTyp());
        task.setDepTaskId(details.getDepTaskId());

        // Auto-compute dates or days based on changes (inclusive)
        if (details.getStDt() != null && details.getNoOfDays() != null) {
            task.setStDt(details.getStDt());
            task.setNoOfDays(details.getNoOfDays());
            task.setEndDt(details.getStDt().plusDays(details.getNoOfDays() - 1));
        } else if (details.getStDt() != null && details.getEndDt() != null) {
            task.setStDt(details.getStDt());
            task.setEndDt(details.getEndDt());
            long days = java.time.temporal.ChronoUnit.DAYS.between(details.getStDt(), details.getEndDt()) + 1;
            task.setNoOfDays((int) days);
        } else {
            task.setNoOfDays(details.getNoOfDays());
            task.setStDt(details.getStDt());
            task.setEndDt(details.getEndDt());
        }

        task.setChkFlg(details.getChkFlg());
        task.setAttaFlg(details.getAttaFlg());
        task.setAttaFileId(details.getAttaFileId());
        task.setNoteTxt(details.getNoteTxt());
        task.setPrcsFlg(details.getPrcsFlg());
        task.setPrcsYesActn(details.getPrcsYesActn());
        task.setAddlRem(details.getAddlRem());
        if (details.getTaskSts() != null) {
            task.setTaskSts(details.getTaskSts());
        }

        TaskLive saved = taskLiveRepository.save(task);
        projectStatusCascadeService.cascadeStatusFromTask(id);

        MilestoneLive milestone = milestoneLiveRepository.findById(saved.getMId())
                .orElseThrow(() -> new RuntimeException("Milestone not found with ID: " + saved.getMId()));

        // Validate limits (Milestone & Project)
        String warning = null;
        if (saved.getStDt() != null && saved.getEndDt() != null) {
            boolean exceedsMilestone = saved.getStDt().isBefore(milestone.getStDt()) ||
                                       (milestone.getEndDt() != null && saved.getEndDt().isAfter(milestone.getEndDt())) ||
                                       (saved.getNoOfDays() != null && milestone.getWrkDays() != null && saved.getNoOfDays() > milestone.getWrkDays());

            boolean exceedsProject = false;
            ProjectLive project = projectLiveRepository.findById(milestone.getPrjId()).orElse(null);
            if (project != null) {
                exceedsProject = saved.getStDt().isBefore(project.getStDt()) ||
                                 (project.getEndDt() != null && saved.getEndDt().isAfter(project.getEndDt())) ||
                                 (saved.getNoOfDays() != null && project.getNoOfDays() != null && saved.getNoOfDays() > project.getNoOfDays());
            }

            if (exceedsMilestone || exceedsProject) {
                warning = "Warning: Task dates/days exceed milestone or project limits. You must also update the Milestone and Project dates/days accordingly.";
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("data", saved);
        if (warning != null) {
            response.put("warning", warning);
        }
        return ResponseEntity.ok(response);
    }

    @Transactional
    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        TaskLive task = taskLiveRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found: " + id));

        String newStatus = body.get("taskSts");
        if (newStatus == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "taskSts is required"));
        }
        String upperStatus = newStatus.toUpperCase().replace(" ", "_");
        if (!List.of("DRAFT","OPEN","WIP","UNDER_REVIEW","SUBMIT_REVIEW","CLOSED","REASSIGN","REWORK","OVER_DUE","HOLD").contains(upperStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: DRAFT, OPEN, WIP, UNDER_REVIEW, SUBMIT_REVIEW, CLOSED, REASSIGN, REWORK, OVER_DUE, HOLD"));
        }
        // SUBMIT_REVIEW is a frontend-only state → maps to WIP
        if ("SUBMIT_REVIEW".equals(upperStatus)) {
            task.setTaskSts(TaskStatusMaster.WIP);
        } else {
            task.setTaskSts(TaskStatusMaster.getByName(newStatus));
        }
        TaskLive saved = taskLiveRepository.save(task);
        projectStatusCascadeService.cascadeStatusFromTask(id);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        taskLiveRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Contributor Endpoints
    // ─────────────────────────────────────────────────────────────────────────

    @GetMapping("/{id}/contributors")
    public ResponseEntity<?> getContributors(@PathVariable Long id) {
        if (!taskLiveRepository.existsById(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Task not found: " + id));
        }
        return ResponseEntity.ok(teamMemberRepository.findByTaskId(id));
    }

    @PostMapping("/{id}/contributors")
    public ResponseEntity<?> assignContributors(@PathVariable Long id, @RequestBody List<TeamMemberDto> dtos) {
        if (!taskLiveRepository.existsById(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Task not found: " + id));
        }
        if (dtos == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Request body cannot be null."));
        }

        teamMemberRepository.deleteByTaskId(id);

        List<TeamMember> saved = dtos.stream()
                .filter(dto -> dto.getEmpId() != null)
                .map(dto -> {
                    TeamMember tm = new TeamMember();
                    tm.setTaskId(id);
                    tm.setEmpId(dto.getEmpId());
                    tm.setAsgnRmk(dto.getAsgnRmk());
                    return teamMemberRepository.save(tm);
                })
                .toList();

        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/{id}/contributors/{tmId}")
    public ResponseEntity<?> removeContributor(@PathVariable Long id, @PathVariable Integer tmId) {
        if (!teamMemberRepository.existsById(tmId)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Contributor not found: " + tmId));
        }
        teamMemberRepository.deleteById(tmId);
        return ResponseEntity.ok(Map.of("message", "Contributor removed successfully."));
    }
}
