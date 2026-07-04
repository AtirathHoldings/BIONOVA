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

        // Change this logic according to your project
        return "vsv.vempati@gmail.com".equalsIgnoreCase(employee.getEmail());
    }

    @GetMapping
    public List<EmployeeIndividualTask> getAllTasks() {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        return employeeRepository.findByEmail(email)
                .map(employee -> {

                    if (isAdminOrManager(employee)) {
                        return repository.findAll();
                    }

                    return repository.findByEmpId(employee.getEmpId());

                })
                .orElse(List.of());
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getTaskById(@PathVariable Long id) {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        Employee employee =
                employeeRepository.findByEmail(email).orElse(null);

        if (employee == null) {

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of(
                            "message",
                            "Unauthorized"));

        }

        return repository.findById(id)
                .map(task -> {

                    if (isAdminOrManager(employee)
                            || employee.getEmpId().equals(task.getEmpId())
                            || employee.getEmpId().equals(task.getAssignedBy())) {

                        return ResponseEntity.ok(task);

                    }

                    return ResponseEntity.status(HttpStatus.FORBIDDEN)
                            .body(Map.of(
                                    "message",
                                    "Access Denied"));

                })
                .orElse(ResponseEntity.notFound().build());

    }

    @GetMapping("/employee/{empId}")
    public List<EmployeeIndividualTask> getEmployeeTasks(
            @PathVariable Long empId) {

        return repository.findByEmpId(empId);

    }

    @GetMapping("/assigned-by/{empId}")
    public List<EmployeeIndividualTask> getAssignedBy(
            @PathVariable Long empId) {

        return repository.findByAssignedBy(empId);

    }

    @GetMapping("/status/{status}")
    public List<EmployeeIndividualTask> getByStatus(
            @PathVariable String status) {

        return repository.findByTaskSts(status);

    }

    @GetMapping("/priority/{priority}")
    public List<EmployeeIndividualTask> getByPriority(
            @PathVariable String priority) {

        return repository.findByPriority(priority);

    }

    @PostMapping
    public ResponseEntity<?> createTask(
            @RequestBody EmployeeIndividualTask task) {

        if (repository.existsByTaskCd(task.getTaskCd())) {

            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "message",
                            "Task Code already exists"));

        }

        if (!employeeRepository.existsById(task.getEmpId())) {

            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "message",
                            "Assigned Employee not found"));

        }

        if (!employeeRepository.existsById(task.getAssignedBy())) {

            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "message",
                            "Assigned By Employee not found"));

        }

        if (task.getTaskSts() == null ||
                task.getTaskSts().isBlank()) {

            task.setTaskSts("DRAFT");

        }

        EmployeeIndividualTask saved =
                repository.save(task);

        return ResponseEntity.ok(saved);

    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateTask(
            @PathVariable Long id,
            @RequestBody EmployeeIndividualTask details) {

        EmployeeIndividualTask task =
                repository.findById(id)
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Task Not Found"));

        if (repository.existsByTaskCdAndEmpTaskIdNot(
                details.getTaskCd(),
                id)) {

            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "message",
                            "Task Code already exists"));

        }

        if (!employeeRepository.existsById(details.getEmpId())) {

            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "message",
                            "Assigned Employee not found"));

        }

        if (!employeeRepository.existsById(details.getAssignedBy())) {

            return ResponseEntity.badRequest()
                    .body(Map.of(
                            "message",
                            "Assigned By Employee not found"));

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

        task.setReviewerId(details.getReviewerId());

        task.setApproverId(details.getApproverId());

        task.setTaskSts(details.getTaskSts());

        task.setRemarks(details.getRemarks());

        task.setSts(details.getSts());

        EmployeeIndividualTask updated =
                repository.save(task);

        return ResponseEntity.ok(updated);

    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(
            @PathVariable Long id) {

        repository.deleteById(id);

        return ResponseEntity.ok().build();

    }

}