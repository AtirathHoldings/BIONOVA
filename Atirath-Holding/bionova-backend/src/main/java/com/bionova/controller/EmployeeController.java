package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class EmployeeController {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private com.bionova.repository.DesignationRepository designationRepository;

    private void populateDesignation(Employee employee) {
        if (employee.getDesigId() != null) {
            designationRepository.findById(employee.getDesigId())
                .ifPresent(d -> {
                    employee.setDesignation(d.getDesigNm());
                    employee.setRole(d.getDesigNm());
                });
        }
    }

    private void populateDesignations(List<Employee> employees) {
        List<com.bionova.entity.DesignationMaster> designations = designationRepository.findAll();
        Map<Integer, String> desigMap = designations.stream()
            .collect(java.util.stream.Collectors.toMap(
                com.bionova.entity.DesignationMaster::getDesigId,
                com.bionova.entity.DesignationMaster::getDesigNm,
                (v1, v2) -> v1
            ));
        for (Employee emp : employees) {
            if (emp.getDesigId() != null) {
                String name = desigMap.get(emp.getDesigId());
                if (name != null) {
                    emp.setDesignation(name);
                    emp.setRole(name);
                }
            }
        }
    }

    @GetMapping("/employees")
    public List<Employee> getEmployees() {
        List<Employee> list = employeeRepository.findAll();
        populateDesignations(list);
        return list;
    }

    @GetMapping("/employees/{id}")
    public ResponseEntity<Employee> getEmployeeById(@PathVariable Long id) {
        return employeeRepository.findById(id)
                .map(emp -> {
                    populateDesignation(emp);
                    return ResponseEntity.ok(emp);
                })
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
                .map(emp -> {
                    populateDesignation(emp);
                    return ResponseEntity.ok(emp);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/employees/fcm-token")
    public ResponseEntity<?> updateFcmToken(@RequestBody Map<String, String> body) {
        String token = body.get("token");
        if (token == null || token.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "FCM token is required"));
        }
        String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> {
                    employee.setFcmToken(token);
                    employeeRepository.save(employee);
                    return ResponseEntity.ok(Map.of("message", "FCM token registered successfully"));
                })
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


        if (employee.getDesignation() != null && !employee.getDesignation().trim().isEmpty()) {
            String desigName = employee.getDesignation().trim();
            com.bionova.entity.DesignationMaster desig = designationRepository.findAll().stream()
                .filter(d -> d.getDesigNm().equalsIgnoreCase(desigName))
                .findFirst()
                .orElseGet(() -> {
                    com.bionova.entity.DesignationMaster newDesig = new com.bionova.entity.DesignationMaster();
                    newDesig.setDesigNm(desigName);
                    newDesig.setSts(true);
                    return designationRepository.save(newDesig);
                });
            employee.setDesigId(desig.getDesigId());
        }

        if (employee.getPassword() != null && !employee.getPassword().isEmpty()) {
            employee.setPassword(
                    new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder()
                            .encode(employee.getPassword())
            );
        }

        Employee saved = employeeRepository.save(employee);
        populateDesignation(saved);
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
        
        if (employeeDetails.getDesignation() != null && !employeeDetails.getDesignation().trim().isEmpty()) {
            String desigName = employeeDetails.getDesignation().trim();
            com.bionova.entity.DesignationMaster desig = designationRepository.findAll().stream()
                .filter(d -> d.getDesigNm().equalsIgnoreCase(desigName))
                .findFirst()
                .orElseGet(() -> {
                    com.bionova.entity.DesignationMaster newDesig = new com.bionova.entity.DesignationMaster();
                    newDesig.setDesigNm(desigName);
                    newDesig.setSts(true);
                    return designationRepository.save(newDesig);
                });
            employee.setDesigId(desig.getDesigId());
        } else {
            employee.setDesigId(employeeDetails.getDesigId());
        }
        
        employee.setCoyId(employeeDetails.getCoyId());
        employee.setPltId(employeeDetails.getPltId());
        employee.setDeptId(employeeDetails.getDeptId());
        employee.setWLoc(employeeDetails.getWLoc());
        employee.setRepManId(employeeDetails.getRepManId());
        employee.setStatus(employeeDetails.getStatus());

        if (employeeDetails.getPassword() != null && !employeeDetails.getPassword().isEmpty()) {
            String rawPwd = employeeDetails.getPassword();
            if (!rawPwd.startsWith("$2a$")) {
                employee.setPassword(new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode(rawPwd));
            } else {
                employee.setPassword(rawPwd);
            }
        }

        Employee updated = employeeRepository.save(employee);
        populateDesignation(updated);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/employees/{id}")
    public ResponseEntity<?> deleteEmployee(@PathVariable Long id) {
        employeeRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
