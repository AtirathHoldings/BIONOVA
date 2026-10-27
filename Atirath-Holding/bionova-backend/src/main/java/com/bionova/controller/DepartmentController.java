package com.bionova.controller;

import com.bionova.entity.DepartmentMaster;
import com.bionova.repository.DepartmentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import java.util.Map;

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
    public ResponseEntity<?> saveDepartment(@RequestBody DepartmentMaster department) {
        if (department.getDeptNm() == null || department.getDeptNm().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Department name is required."));
        }
        if (department.getDeptNm().trim().matches(".*[^a-zA-Z0-9\\s].*")) {
            return ResponseEntity.badRequest().body(Map.of("message", "Special characters are not allowed in Department Name."));
        }
        if (!department.getDeptNm().trim().matches(".*[a-zA-Z].*")) {
            return ResponseEntity.badRequest().body(Map.of("message", "Department name must contain at least one letter."));
        }
        if (department.getDeptCode() != null && !department.getDeptCode().trim().isEmpty()) {
            if (departmentRepository.existsByDeptCodeIgnoreCase(department.getDeptCode().trim())) {
                return ResponseEntity.badRequest().body(Map.of("message", "Department code already exists."));
            }
        }
        if (departmentRepository.existsByDeptNmIgnoreCase(department.getDeptNm().trim())) {
            return ResponseEntity.badRequest().body(Map.of("message", "Department name already exists."));
        }
        DepartmentMaster saved = departmentRepository.save(department);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/departments/{id}")
    public ResponseEntity<?> updateDepartment(@PathVariable Long id, @RequestBody DepartmentMaster details) {
        DepartmentMaster dept = departmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Department not found"));
        if (details.getDeptNm() != null && !details.getDeptNm().trim().isEmpty()) {
            if (details.getDeptNm().trim().matches(".*[^a-zA-Z0-9\\s].*")) {
                return ResponseEntity.badRequest().body(Map.of("message", "Special characters are not allowed in Department Name."));
            }
            if (!details.getDeptNm().trim().matches(".*[a-zA-Z].*")) {
                return ResponseEntity.badRequest().body(Map.of("message", "Department name must contain at least one letter."));
            }
            if (departmentRepository.existsByDeptNmIgnoreCaseAndDeptIdNot(details.getDeptNm().trim(), id)) {
                return ResponseEntity.badRequest().body(Map.of("message", "Department name already exists."));
            }
        }
        if (details.getDeptCode() != null && !details.getDeptCode().trim().isEmpty()) {
            if (departmentRepository.existsByDeptCodeIgnoreCaseAndDeptIdNot(details.getDeptCode().trim(), id)) {
                return ResponseEntity.badRequest().body(Map.of("message", "Department code already exists."));
            }
        }
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