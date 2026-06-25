package com.bionova.controller;

import com.bionova.entity.EmployeeIndividualTask;
import com.bionova.repository.EmployeeIndividualTaskRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/individual-tasks")
public class EmployeeIndividualTaskController {

    @Autowired
    private EmployeeIndividualTaskRepository repository;

    @GetMapping
    public List<EmployeeIndividualTask> getAllTasks() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<EmployeeIndividualTask> getTaskById(@PathVariable Long id) {
        return repository.findById(id)
                .map(ResponseEntity::ok)
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
