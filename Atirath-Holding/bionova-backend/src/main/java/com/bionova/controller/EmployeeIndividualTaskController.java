package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.entity.EmployeeIndividualTask;
import com.bionova.repository.EmployeeIndividualTaskRepository;
import com.bionova.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/individual-tasks")
public class EmployeeIndividualTaskController {

    @Autowired
    private EmployeeIndividualTaskRepository repository;

    @Autowired
    private EmployeeRepository employeeRepository;

    private boolean isAdminOrManager(Employee employee) {
        if (employee == null) {
            return false;
        }
        // Since role column is removed, we treat siva@atirath.com as admin
        return "siva@atirath.com".equalsIgnoreCase(employee.getEmail());
    }

    @GetMapping
    public List<EmployeeIndividualTask> getAllTasks() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> {
                    if (isAdminOrManager(employee)) {
                        return repository.findAll();
                    } else {
                        return repository.findByAssignedTo(employee.getEmpId());
                    }
                })
                .orElse(List.of());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getTaskById(@PathVariable Long id) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);
        if (employee == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Unauthorized"));
        }

        return repository.findById(id)
                .map(task -> {
                    if (isAdminOrManager(employee) || 
                        employee.getEmpId().equals(task.getAssignedTo()) ||
                        employee.getEmpId().equals(task.getAssignedBy())) {
                        return ResponseEntity.ok(task);
                    } else {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
                    }
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/assigned-to/{empId}")
    public List<EmployeeIndividualTask> getTasksAssignedTo(@PathVariable Long empId) {
        return repository.findByAssignedTo(empId);
    }

    @GetMapping("/assigned-by/{empId}")
    public List<EmployeeIndividualTask> getTasksAssignedBy(@PathVariable Long empId) {
        return repository.findByAssignedBy(empId);
    }

    @PostMapping
    public ResponseEntity<EmployeeIndividualTask> createTask(@RequestBody EmployeeIndividualTask task) {
        EmployeeIndividualTask saved = repository.save(task);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<EmployeeIndividualTask> updateTask(@PathVariable Long id, @RequestBody EmployeeIndividualTask details) {
        EmployeeIndividualTask task = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Individual task not found: " + id));

        task.setTaskCd(details.getTaskCd());
        task.setTaskNm(details.getTaskNm());
        task.setTaskDesc(details.getTaskDesc());
        task.setAssignedTo(details.getAssignedTo());
        task.setAssignedBy(details.getAssignedBy());
        task.setAssignedDt(details.getAssignedDt());
        task.setDueDt(details.getDueDt());
        task.setToBeCompletedDt(details.getToBeCompletedDt());
        task.setPriority(details.getPriority());
        task.setTaskSts(details.getTaskSts());
        task.setRemarks(details.getRemarks());
        task.setSts(details.getSts());

        EmployeeIndividualTask saved = repository.save(task);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        repository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
