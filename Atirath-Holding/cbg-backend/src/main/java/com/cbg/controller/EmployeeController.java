package com.cbg.controller;

import com.cbg.entity.Employee;
import com.cbg.repository.EmployeeRepository;
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

    @PostMapping("/employees")
    public ResponseEntity<Employee> saveEmployee(@RequestBody Employee employee) {
        if (employee.getRole() == null || employee.getRole().isEmpty()) {
            employee.setRole("user"); // default role
        }
        if (employee.getPassword() != null && !employee.getPassword().isEmpty()) {
            employee.setPassword(new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode(employee.getPassword()));
        }
        Employee saved = employeeRepository.save(employee);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/employees/{id}")
    public ResponseEntity<Employee> updateEmployee(@PathVariable Long id, @RequestBody Employee employeeDetails) {
        Employee employee = employeeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Employee not found with id: " + id));

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
