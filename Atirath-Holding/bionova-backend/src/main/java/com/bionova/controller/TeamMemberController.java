package com.bionova.controller;

import com.bionova.dto.TeamMemberDto;
import com.bionova.entity.Employee;
import com.bionova.entity.TeamMember;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.TeamMemberRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * REST controller for managing team members assigned to a task.
 *
 * Base URL : /api/team-members
 *
 * Endpoints:
 *   GET    /by-task/{taskId}          → list all members of a task
 *   GET    /by-employee/{empId}       → all tasks an employee is part of
 *   POST   /                          → assign a single employee to a task
 *   POST   /bulk/{taskId}             → assign multiple employees at once
 *   PUT    /{tmId}                    → update remark of an assignment
 *   DELETE /{tmId}                    → remove a single member
 *   DELETE /by-task/{taskId}          → remove ALL members from a task
 */
@RestController
@RequestMapping("/api/team-members")
public class TeamMemberController {

    @Autowired
    private TeamMemberRepository teamMemberRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    // ─────────────────────────────────────────────────────────────────────────
    // Helper
    // ─────────────────────────────────────────────────────────────────────────

    private Employee currentEmployee() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email).orElse(null);
    }

    private boolean isAdmin(Employee emp) {
        return emp != null && "siva@atirath.com".equalsIgnoreCase(emp.getEmail());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET  /by-task/{taskId}
    // ─────────────────────────────────────────────────────────────────────────

    @GetMapping("/by-task/{taskId}")
    public ResponseEntity<?> getByTask(@PathVariable Long taskId) {
        if (!taskLiveRepository.existsById(taskId)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Task not found: " + taskId));
        }
        List<TeamMember> members = teamMemberRepository.findByTaskId(taskId);
        return ResponseEntity.ok(members);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET  /by-employee/{empId}
    // ─────────────────────────────────────────────────────────────────────────

    @GetMapping("/by-employee/{empId}")
    public ResponseEntity<?> getByEmployee(@PathVariable Long empId) {
        Employee caller = currentEmployee();
        if (caller == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Unauthorized"));
        }
        // Allow admin or the employee themselves
        if (!isAdmin(caller) && !caller.getEmpId().equals(empId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("message", "Access denied"));
        }
        return ResponseEntity.ok(teamMemberRepository.findByEmpId(empId));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST /   → assign ONE employee to a task
    // ─────────────────────────────────────────────────────────────────────────

    @PostMapping
    public ResponseEntity<?> assignOne(@RequestBody TeamMemberDto dto) {
        if (dto.getTaskId() == null || dto.getEmpId() == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "taskId and empId are required."));
        }
        if (!taskLiveRepository.existsById(dto.getTaskId())) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Task not found: " + dto.getTaskId()));
        }
        if (teamMemberRepository.existsByTaskIdAndEmpId(dto.getTaskId(), dto.getEmpId())) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("message", "Employee " + dto.getEmpId()
                            + " is already assigned to task " + dto.getTaskId()));
        }

        TeamMember tm = new TeamMember();
        tm.setTaskId(dto.getTaskId());
        tm.setEmpId(dto.getEmpId());
        tm.setAsgnRmk(dto.getAsgnRmk());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(teamMemberRepository.save(tm));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST /bulk/{taskId}  → assign MULTIPLE employees at once
    //
    // Request body: List<TeamMemberDto>  (taskId in body is ignored; path wins)
    // ─────────────────────────────────────────────────────────────────────────

    @PostMapping("/bulk/{taskId}")
    public ResponseEntity<?> assignBulk(
            @PathVariable Long taskId,
            @RequestBody List<TeamMemberDto> dtos) {

        if (!taskLiveRepository.existsById(taskId)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "Task not found: " + taskId));
        }

        if (dtos == null || dtos.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Request body must be a non-empty list of employees."));
        }

        List<TeamMember> saved = dtos.stream()
                .filter(dto -> dto.getEmpId() != null)
                .filter(dto -> !teamMemberRepository.existsByTaskIdAndEmpId(taskId, dto.getEmpId()))
                .map(dto -> {
                    TeamMember tm = new TeamMember();
                    tm.setTaskId(taskId);
                    tm.setEmpId(dto.getEmpId());
                    tm.setAsgnRmk(dto.getAsgnRmk());
                    return teamMemberRepository.save(tm);
                })
                .toList();

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(Map.of(
                        "assigned", saved.size(),
                        "members", saved
                ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PUT  /{tmId}  → update remark only
    // ─────────────────────────────────────────────────────────────────────────

    @PutMapping("/{tmId}")
    public ResponseEntity<?> update(@PathVariable Integer tmId,
                                    @RequestBody TeamMemberDto dto) {
        TeamMember tm = teamMemberRepository.findById(tmId)
                .orElse(null);
        if (tm == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "TeamMember not found: " + tmId));
        }
        tm.setAsgnRmk(dto.getAsgnRmk());
        return ResponseEntity.ok(teamMemberRepository.save(tm));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DELETE /{tmId}  → remove a single assignment
    // ─────────────────────────────────────────────────────────────────────────

    @DeleteMapping("/{tmId}")
    public ResponseEntity<?> deleteOne(@PathVariable Integer tmId) {
        if (!teamMemberRepository.existsById(tmId)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("message", "TeamMember not found: " + tmId));
        }
        teamMemberRepository.deleteById(tmId);
        return ResponseEntity.ok(Map.of("message", "Removed successfully."));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DELETE /by-task/{taskId}  → remove ALL members from a task
    // ─────────────────────────────────────────────────────────────────────────

    @DeleteMapping("/by-task/{taskId}")
    public ResponseEntity<?> deleteAllByTask(@PathVariable Long taskId) {
        teamMemberRepository.deleteByTaskId(taskId);
        return ResponseEntity.ok(Map.of("message", "All members removed from task " + taskId));
    }
}
