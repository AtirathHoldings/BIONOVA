package com.bionova.controller;

import com.bionova.entity.DeptCoyPltMap;
import com.bionova.entity.Employee;
import com.bionova.repository.DeptCoyPltMapRepository;
import com.bionova.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class DeptCoyPltMapController {

    @Autowired
    private DeptCoyPltMapRepository deptCoyPltMapRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    // ─── Dept-Coy-Plt Mapping CRUD ─────────────────────────────────────────────

    @GetMapping("/dept-coy-plt-maps")
    public List<DeptCoyPltMap> getAllMappings() {
        return deptCoyPltMapRepository.findAll();
    }

    @GetMapping("/dept-coy-plt-maps/by-company/{coyId}")
    public List<DeptCoyPltMap> getMappingsByCompany(@PathVariable Long coyId) {
        return deptCoyPltMapRepository.findByCoyId(coyId);
    }

    @GetMapping("/dept-coy-plt-maps/by-company/{coyId}/by-plant/{pltId}")
    public List<DeptCoyPltMap> getMappingsByCompanyAndPlant(
            @PathVariable Long coyId,
            @PathVariable Long pltId) {
        return deptCoyPltMapRepository.findByCoyIdAndPltId(coyId, pltId);
    }

    @PostMapping("/dept-coy-plt-maps")
    public ResponseEntity<?> createMapping(@RequestBody DeptCoyPltMap mapping) {
        if (deptCoyPltMapRepository.existsByDeptIdAndCoyIdAndPltId(
                mapping.getDeptId(), mapping.getCoyId(), mapping.getPltId())) {
            return ResponseEntity.badRequest()
                    .body(java.util.Map.of("message", "This Department-Company-Plant mapping already exists."));
        }
        DeptCoyPltMap saved = deptCoyPltMapRepository.save(mapping);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/dept-coy-plt-maps/{id}")
    public ResponseEntity<?> updateMapping(@PathVariable Long id, @RequestBody DeptCoyPltMap details) {
        DeptCoyPltMap mapping = deptCoyPltMapRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Mapping not found with id: " + id));

        if (deptCoyPltMapRepository.existsByDeptIdAndCoyIdAndPltIdAndMapIdNot(
                details.getDeptId(), details.getCoyId(), details.getPltId(), id)) {
            return ResponseEntity.badRequest()
                    .body(java.util.Map.of("message", "This Department-Company-Plant mapping already exists."));
        }

        mapping.setDeptId(details.getDeptId());
        mapping.setCoyId(details.getCoyId());
        mapping.setPltId(details.getPltId());
        mapping.setSts(details.getSts());

        DeptCoyPltMap saved = deptCoyPltMapRepository.save(mapping);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/dept-coy-plt-maps/{id}")
    public ResponseEntity<?> deleteMapping(@PathVariable Long id) {
        deptCoyPltMapRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // ─── Employee Filter Endpoint ───────────────────────────────────────────────
    //
    // Usage:
    //   GET /api/employees/filter?coyId=1              → employees of company 1
    //   GET /api/employees/filter?coyId=1&pltId=2      → employees of company 1, plant 2
    //   GET /api/employees/filter?coyId=1&pltId=2&deptId=3  → + department filter via mapping
    //
    // How it works:
    //   1. Filter employees by coyId (and optionally pltId) directly on employee_master.
    //   2. If deptId is also given, look up valid deptIds from dept_coy_plt_map for that
    //      company+plant and further filter employees whose deptId is in that set.

    @GetMapping("/employees/filter")
    public ResponseEntity<?> filterEmployees(
            @RequestParam(required = false) Integer coyId,
            @RequestParam(required = false) Integer pltId,
            @RequestParam(required = false) Integer deptId) {

        List<Employee> employees;

        if (coyId != null && pltId != null && deptId != null) {
            // All three filters
            employees = employeeRepository.findByCoyIdAndPltIdAndDeptId(coyId, pltId, deptId);
        } else if (coyId != null && pltId != null) {
            // Company + Plant
            employees = employeeRepository.findByCoyIdAndPltId(coyId, pltId);
        } else if (coyId != null && deptId != null) {
            // Company + Department
            employees = employeeRepository.findByCoyIdAndDeptId(coyId, deptId);
        } else if (coyId != null) {
            // Company only
            employees = employeeRepository.findByCoyId(coyId);
        } else if (pltId != null) {
            // Plant only
            employees = employeeRepository.findByPltId(pltId);
        } else if (deptId != null) {
            // Department only
            employees = employeeRepository.findByDeptId(deptId);
        } else {
            // No filter → return all
            employees = employeeRepository.findAll();
        }

        return ResponseEntity.ok(employees);
    }
}