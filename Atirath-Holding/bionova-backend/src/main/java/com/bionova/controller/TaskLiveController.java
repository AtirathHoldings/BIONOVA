package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

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

    @GetMapping
    public List<TaskLive> getAll() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> {
                    if ("admin".equalsIgnoreCase(employee.getRole()) || "manager".equalsIgnoreCase(employee.getRole())) {
                        return taskLiveRepository.findAll();
                    } else {
                        return taskLiveRepository.findByEmpId(employee.getEmpId());
                    }
                })
                .orElse(List.of());
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
                    if ("admin".equalsIgnoreCase(employee.getRole()) || 
                        "manager".equalsIgnoreCase(employee.getRole()) || 
                        employee.getEmpId().equals(task.getEmpId())) {
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
        return employeeRepository.findByEmail(email)
                .map(employee -> {
                    if ("admin".equalsIgnoreCase(employee.getRole()) || "manager".equalsIgnoreCase(employee.getRole())) {
                        return taskLiveRepository.findByMilestoneId(mId);
                    } else {
                        return taskLiveRepository.findByMilestoneIdAndEmpId(mId, employee.getEmpId());
                    }
                })
                .orElse(List.of());
    }

    @GetMapping("/by-employee/{empId}")
    public ResponseEntity<?> getByEmployee(@PathVariable Long empId) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);
        if (employee == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Unauthorized"));
        }

        if ("admin".equalsIgnoreCase(employee.getRole()) || 
            "manager".equalsIgnoreCase(employee.getRole()) || 
            employee.getEmpId().equals(empId)) {
            return ResponseEntity.ok(taskLiveRepository.findByEmpId(empId));
        } else {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
        }
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody TaskLive task) {
        if (task.getTaskCd() != null && !task.getTaskCd().trim().isEmpty()) {
            if (taskLiveRepository.existsByTaskCd(task.getTaskCd())) {
                return ResponseEntity.badRequest().body(Map.of("message", "Task code already exists."));
            }
        }

        MilestoneLive milestone = milestoneLiveRepository.findById(task.getMId())
                .orElseThrow(() -> new RuntimeException("Milestone not found with ID: " + task.getMId()));

        if (task.getTaskSts() == null) {
            task.setTaskSts("OPEN");
        }

        // Auto-compute dates or days
        if (task.getStDt() != null && task.getNoOfDays() != null) {
            task.setEndDt(task.getStDt().plusDays(task.getNoOfDays()));
        } else if (task.getStDt() != null && task.getEndDt() != null) {
            long days = java.time.temporal.ChronoUnit.DAYS.between(task.getStDt(), task.getEndDt());
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

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody TaskLive details) {
        TaskLive task = taskLiveRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found: " + id));

        if (details.getTaskCd() != null && !details.getTaskCd().trim().isEmpty()) {
            if (taskLiveRepository.existsByTaskCdAndTaskIdNot(details.getTaskCd(), id)) {
                return ResponseEntity.badRequest().body(Map.of("message", "Task code already exists."));
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

        // Auto-compute dates or days based on changes
        if (details.getStDt() != null && details.getNoOfDays() != null) {
            task.setStDt(details.getStDt());
            task.setNoOfDays(details.getNoOfDays());
            task.setEndDt(details.getStDt().plusDays(details.getNoOfDays()));
        } else if (details.getStDt() != null && details.getEndDt() != null) {
            task.setStDt(details.getStDt());
            task.setEndDt(details.getEndDt());
            long days = java.time.temporal.ChronoUnit.DAYS.between(details.getStDt(), details.getEndDt());
            task.setNoOfDays((int) days);
        } else {
            task.setNoOfDays(details.getNoOfDays());
            task.setStDt(details.getStDt());
            task.setEndDt(details.getEndDt());
        }

        task.setChkFlg(details.getChkFlg());
        task.setChkId(details.getChkId());
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

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        TaskLive task = taskLiveRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found: " + id));

        String newStatus = body.get("taskSts");
        if (!List.of("OPEN","WIP","SUBMIT_REVIEW","UNDER_REVIEW","COMPLETED","REWORK").contains(newStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: OPEN, WIP, SUBMIT_REVIEW, UNDER_REVIEW, COMPLETED, REWORK"));
        }
        task.setTaskSts(newStatus);
        return ResponseEntity.ok(taskLiveRepository.save(task));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        taskLiveRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
