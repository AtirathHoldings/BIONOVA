package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class EmployeeController {

    @Autowired
    private EmployeeRepository employeeRepository;

    @GetMapping("/employees")
    public List<Employee> getEmployees() {
        return employeeRepository.findAll();
    }

    @GetMapping("/employees/{id}")
    public ResponseEntity<Employee> getEmployeeById(@PathVariable Long id) {
        return employeeRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Exposes the profile of the currently authenticated employee.
     * Extracts email from SecurityContextHolder.
     */
    @GetMapping("/profile")
    public ResponseEntity<?> getProfile() {
        String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/employees")
    public ResponseEntity<?> saveEmployee(@RequestBody Employee employee) {

        System.out.println("EMPLOYEE POST API HIT");

        if (employee.getEmpCode() != null && !employee.getEmpCode().trim().isEmpty() && employeeRepository.existsByEmpCode(employee.getEmpCode())) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "Employee code already exists."));
        }
        if (employee.getEmail() != null && !employee.getEmail().trim().isEmpty() && employeeRepository.existsByEmail(employee.getEmail())) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "Employee email already exists."));
        }
        if (employee.getMobNum() != null && !employee.getMobNum().trim().isEmpty() && employeeRepository.existsByMobNum(employee.getMobNum())) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "Employee mobile number already exists."));
        }

        if (employee.getRole() == null || employee.getRole().isEmpty()) {
            employee.setRole("user");
        }

        if (employee.getPassword() != null && !employee.getPassword().isEmpty()) {
            employee.setPassword(
                    new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder()
                            .encode(employee.getPassword())
            );
        }

        Employee saved = employeeRepository.save(employee);
        return ResponseEntity.ok(saved);
    }
    @PutMapping("/employees/{id}")
    public ResponseEntity<?> updateEmployee(@PathVariable Long id, @RequestBody Employee employeeDetails) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Employee not found with id: " + id));

        if (employeeDetails.getEmpCode() != null && !employeeDetails.getEmpCode().trim().isEmpty() && employeeRepository.existsByEmpCodeAndEmpIdNot(employeeDetails.getEmpCode(), id)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "Employee code already exists."));
        }
        if (employeeDetails.getEmail() != null && !employeeDetails.getEmail().trim().isEmpty() && employeeRepository.existsByEmailAndEmpIdNot(employeeDetails.getEmail(), id)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "Employee email already exists."));
        }
        if (employeeDetails.getMobNum() != null && !employeeDetails.getMobNum().trim().isEmpty() && employeeRepository.existsByMobNumAndEmpIdNot(employeeDetails.getMobNum(), id)) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", "Employee mobile number already exists."));
        }

        employee.setEmpCode(employeeDetails.getEmpCode());
        employee.setFirstName(employeeDetails.getFirstName());
        employee.setLastName(employeeDetails.getLastName());
        employee.setGender(employeeDetails.getGender());
        employee.setDob(employeeDetails.getDob());
        employee.setEmail(employeeDetails.getEmail());
        employee.setMobNum(employeeDetails.getMobNum());
        employee.setBldGrp(employeeDetails.getBldGrp());
        employee.setAddress(employeeDetails.getAddress());
        employee.setPhotoUrl(employeeDetails.getPhotoUrl());
        employee.setDoj(employeeDetails.getDoj());
        employee.setEmpTyp(employeeDetails.getEmpTyp());
        employee.setDesigId(employeeDetails.getDesigId());
        employee.setCoyId(employeeDetails.getCoyId());
        employee.setPltId(employeeDetails.getPltId());
        employee.setDeptId(employeeDetails.getDeptId());
        employee.setWLoc(employeeDetails.getWLoc());
        employee.setRepManId(employeeDetails.getRepManId());
        employee.setStatus(employeeDetails.getStatus());
        if (employeeDetails.getRole() != null) {
            employee.setRole(employeeDetails.getRole());
        }
        if (employeeDetails.getPassword() != null && !employeeDetails.getPassword().isEmpty()) {
            String rawPwd = employeeDetails.getPassword();
            if (!rawPwd.startsWith("$2a$")) {
                employee.setPassword(new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode(rawPwd));
            } else {
                employee.setPassword(rawPwd);
            }
        }

        Employee updated = employeeRepository.save(employee);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/employees/{id}")
    public ResponseEntity<?> deleteEmployee(@PathVariable Long id) {
        employeeRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
