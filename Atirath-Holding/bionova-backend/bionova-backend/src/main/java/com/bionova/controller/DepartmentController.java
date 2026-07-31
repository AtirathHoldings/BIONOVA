package com.bionova.controller;

import com.bionova.entity.DepartmentMaster;
import com.bionova.repository.DepartmentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class DepartmentController {

    @Autowired
    private DepartmentRepository departmentRepository;

    @GetMapping("/departments")
    public List<DepartmentMaster> getDepartments() {
        return departmentRepository.findAll();
    }

    @PostMapping("/departments")
    public ResponseEntity<DepartmentMaster> saveDepartment(@RequestBody DepartmentMaster department) {
        DepartmentMaster saved = departmentRepository.save(department);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/departments/{id}")
    public ResponseEntity<DepartmentMaster> updateDepartment(@PathVariable Long id, @RequestBody DepartmentMaster details) {
        DepartmentMaster dept = departmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Department not found"));
        dept.setDeptNm(details.getDeptNm());
        dept.setDeptCode(details.getDeptCode());
        dept.setDescr(details.getDescr());
        dept.setSts(details.getSts());
        DepartmentMaster saved = departmentRepository.save(dept);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/departments/{id}")
    public ResponseEntity<?> deleteDepartment(@PathVariable Long id) {
        departmentRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}