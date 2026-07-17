package com.bionova.controller;

import com.bionova.dto.AssignmentRequest;
import com.bionova.dto.TeamMemberDto;
import com.bionova.entity.Employee;
import com.bionova.entity.Assignment;
import com.bionova.entity.TeamMember;
import com.bionova.entity.TaskStatusMaster;
import com.bionova.entity.TaskPriorityMaster;
import com.bionova.repository.AssignmentRepository;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.TeamMemberRepository;
import com.bionova.service.CalendarService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/assignments")
public class AssignmentController {

    @Autowired
    private AssignmentRepository repository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private com.bionova.repository.ProcessConfigRepository processConfigRepo;

    @Autowired
    private com.bionova.repository.ChecklistMasterRepository checklistRepo;

    @Autowired
    private CalendarService calendarService;

    @Autowired
    private TeamMemberRepository teamMemberRepository;

    private boolean isAdminOrManager(Employee employee) {
        if (employee == null) {
            return false;
        }
        return "vsv.vempati@gmail.com".equalsIgnoreCase(employee.getEmail());
    }

    private boolean isReviewerOrApproverForAssignment(Long empTaskId, Long empId) {
        List<com.bionova.entity.ProcessConfig> configs = processConfigRepo.findByEmpTaskIdOrderByOrdrIdAsc(empTaskId);
        for (com.bionova.entity.ProcessConfig pc : configs) {
            if (empId.equals(pc.getEmpId())) {
                return true;
            }
        }
        return false;
    }

    private void populateReviewerAndApprover(Assignment task) {
        if (task == null) return;
        
        if (task.getEmpId() != null) {
            employeeRepository.findById(task.getEmpId()).ifPresent(emp -> {
                String lastName = emp.getLastName() != null ? emp.getLastName() : "";
                task.setEmpNm((emp.getFirstName() + " " + lastName).trim());
            });
        }
        if (task.getAssignedBy() != null) {
            employeeRepository.findById(task.getAssignedBy()).ifPresent(emp -> {
                String lastName = emp.getLastName() != null ? emp.getLastName() : "";
                task.setAssignedByNm((emp.getFirstName() + " " + lastName).trim());
            });
        }

        List<com.bionova.entity.ProcessConfig> configs = processConfigRepo.findByEmpTaskIdOrderByOrdrIdAsc(task.getEmpTaskId());
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

    private void populateReviewerAndApprover(List<Assignment> tasks) {
        if (tasks == null) return;
        for (Assignment task : tasks) {
            populateReviewerAndApprover(task);
        }
    }

    @GetMapping
    public List<Assignment> getAllTasks() {
        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        List<Assignment> tasks = employeeRepository.findByEmail(email)
                .map(employee -> {
                    if (isAdminOrManager(employee)) {
                        return repository.findAll();
                    }
                    return repository.findTasksForEmployee(employee.getEmpId());
                })
                .orElse(List.of());
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getTaskById(@PathVariable Long id) {
        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        Employee employee = employeeRepository.findByEmail(email).orElse(null);
        if (employee == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Unauthorized"));
        }

        return repository.findById(id)
                .map(task -> {
                    if (isAdminOrManager(employee)
                            || employee.getEmpId().equals(task.getEmpId())
                            || employee.getEmpId().equals(task.getAssignedBy())
                            || isReviewerOrApproverForAssignment(task.getEmpTaskId(), employee.getEmpId())) {
                        populateReviewerAndApprover(task);
                        return ResponseEntity.ok(task);
                    }
                    return ResponseEntity.status(HttpStatus.FORBIDDEN)
                            .body(Map.of("message", "Access Denied"));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/employee/{empId}")
    public List<Assignment> getEmployeeTasks(@PathVariable Long empId) {
        List<Assignment> tasks = repository.findAssignedToMe(empId);
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    @GetMapping("/assigned-by/{empId}")
    public List<Assignment> getAssignedBy(@PathVariable Long empId) {
        List<Assignment> tasks = repository.findAssignedByMe(empId);
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    @GetMapping("/self/{empId}")
    public List<Assignment> getSelfTasks(@PathVariable Long empId) {
        List<Assignment> tasks = repository.findSelfAssigned(empId);
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    @GetMapping("/status/{status}")
    public List<Assignment> getByStatus(@PathVariable String status) {
        List<Assignment> tasks = repository.findByTaskSts(TaskStatusMaster.getByName(status));
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    @GetMapping("/priority/{priority}")
    public List<Assignment> getByPriority(@PathVariable String priority) {
        List<Assignment> tasks = repository.findByPriority(TaskPriorityMaster.getByName(priority));
        populateReviewerAndApprover(tasks);
        return tasks;
    }

    @PostMapping("/assign-with-calendar")
    public ResponseEntity<?> assignTaskWithCalendar(@RequestBody AssignmentRequest request) {
        Assignment task = request.getTask();

        if (repository.existsByTaskCdAndEmpId(task.getTaskCd(), task.getEmpId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Task Code already exists for this employee"));
        }

        if (!employeeRepository.existsById(task.getEmpId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Assigned Employee not found"));
        }

        if (!employeeRepository.existsById(task.getAssignedBy())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Assigned By Employee not found"));
        }

        if (task.getTaskSts() == null) {
            task.setTaskSts(TaskStatusMaster.OPEN);
        }

        if (task.getStDt() != null && request.getNoOfDays() != null) {
            java.time.LocalDate endDt = calendarService.calculateEndDate(
                    task.getStDt(), request.getNoOfDays(),
                    request.isExcludeSat(), request.isExcludeSun(), request.isIncludeMandatory(),
                    request.getCoyId(), request.getPltId(), request.isExtHolidays());
            task.setEndDt(endDt);
        }

        Assignment saved = repository.save(task);
        populateReviewerAndApprover(saved);
        return ResponseEntity.ok(saved);
    }

    @PostMapping
    public ResponseEntity<?> createTask(@RequestBody Assignment task) {
        if (repository.existsByTaskCdAndEmpId(task.getTaskCd(), task.getEmpId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Task Code already exists for this employee"));
        }

        if (!employeeRepository.existsById(task.getEmpId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Assigned Employee not found"));
        }

        if (!employeeRepository.existsById(task.getAssignedBy())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Assigned By Employee not found"));
        }

        if (task.getTaskSts() == null) {
            task.setTaskSts(TaskStatusMaster.DRAFT);
        }

        Assignment saved = repository.save(task);
        populateReviewerAndApprover(saved);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateTask(@PathVariable Long id, @RequestBody Assignment details) {
        Assignment task = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task Not Found"));

        Long empId = details.getEmpId() != null ? details.getEmpId() : task.getEmpId();
        if (repository.existsByTaskCdAndEmpIdAndEmpTaskIdNot(details.getTaskCd(), empId, id)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Task Code already exists for this employee"));
        }

        if (!employeeRepository.existsById(details.getEmpId())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Assigned Employee not found"));
        }

        if (!employeeRepository.existsById(details.getAssignedBy())) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Assigned By Employee not found"));
        }

        task.setTaskCd(details.getTaskCd());
        task.setTaskNm(details.getTaskNm());
        task.setTaskDesc(details.getTaskDesc());
        task.setEmpId(details.getEmpId());
        task.setAssignedBy(details.getAssignedBy());
        task.setTaskAsgnTo(details.getTaskAsgnTo());
        task.setStDt(details.getStDt());
        task.setEndDt(details.getEndDt());
        task.setPriority(details.getPriority());
        task.setChkFlg(details.getChkFlg());
        task.setAttaFlg(details.getAttaFlg());
        task.setPrcsFlg(details.getPrcsFlg());
        task.setPrcsYesActn(details.getPrcsYesActn());
        task.setTaskSts(details.getTaskSts());
        task.setRemarks(details.getRemarks());
        task.setSts(details.getSts());

        Assignment updated = repository.save(task);
        populateReviewerAndApprover(updated);
        return ResponseEntity.ok(updated);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        Assignment task = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found: " + id));

        String newStatus = body.get("taskSts");
        if (newStatus == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "taskSts is required"));
        }
        String upperStatus = newStatus.toUpperCase().replace(" ", "_");
        if (!List.of("DRAFT", "OPEN", "WIP", "UNDER_REVIEW", "SUBMIT_REVIEW", "COMPLETED", "REASSIGN", "REWORK", "OVER_DUE", "HOLD").contains(upperStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: DRAFT, OPEN, WIP, UNDER_REVIEW, SUBMIT_REVIEW, COMPLETED, REASSIGN, REWORK, OVER_DUE, HOLD"));
        }
        // SUBMIT_REVIEW is a frontend-only state → maps to WIP
        if ("SUBMIT_REVIEW".equals(upperStatus)) {
            task.setTaskSts(TaskStatusMaster.WIP);
        } else {
            task.setTaskSts(TaskStatusMaster.getByName(newStatus));
        }
        Assignment saved = repository.save(task);
        populateReviewerAndApprover(saved);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        processConfigRepo.deleteByEmpTaskId(id);
        checklistRepo.deleteByEmpTaskId(id);
        repository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Contributor Endpoints
    // ─────────────────────────────────────────────────────────────────────────

    @GetMapping("/{id}/contributors")
    public ResponseEntity<?> getContributors(@PathVariable Long id) {
        if (!repository.existsById(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Assignment not found: " + id));
        }
        return ResponseEntity.ok(teamMemberRepository.findByEmpTaskId(id));
    }

    @PostMapping("/{id}/contributors")
    public ResponseEntity<?> assignContributors(@PathVariable Long id, @RequestBody List<TeamMemberDto> dtos) {
        if (!repository.existsById(id)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Assignment not found: " + id));
        }
        if (dtos == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Request body cannot be null."));
        }

        teamMemberRepository.deleteByEmpTaskId(id);

        List<TeamMember> saved = dtos.stream()
                .filter(dto -> dto.getEmpId() != null)
                .map(dto -> {
                    TeamMember tm = new TeamMember();
                    tm.setEmpTaskId(id);
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
