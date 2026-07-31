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

    @Autowired
    private com.bionova.repository.CompanyRepository companyRepository;

    @Autowired
    private com.bionova.repository.PlantRepository plantRepository;

    @Autowired
    private com.bionova.repository.DepartmentRepository departmentRepository;

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

    private void populateCompanyAndPlant(Employee employee) {
        if (employee == null) return;
        if (employee.getCoyId() != null) {
            companyRepository.findById(employee.getCoyId().longValue())
                .ifPresent(c -> employee.setCoyNm(c.getCoyNm()));
        }
        if (employee.getPltId() != null) {
            plantRepository.findById(employee.getPltId().longValue())
                .ifPresent(p -> employee.setPltNm(p.getPltNm()));
        }
        if (employee.getDeptId() != null) {
            departmentRepository.findById(employee.getDeptId().longValue())
                .ifPresent(d -> employee.setDeptNm(d.getDeptNm()));
        }
        if (employee.getRepManId() != null) {
            employeeRepository.findById(employee.getRepManId().longValue())
                .ifPresent(mgr -> {
                    String name = ((mgr.getFirstName() != null ? mgr.getFirstName() : "") + " " +
                                  (mgr.getLastName() != null ? mgr.getLastName() : "")).trim();
                    employee.setRepManNm(name.isEmpty() ? null : name);
                });
        }
    }

    private void populateCompanyAndPlantNames(List<Employee> employees) {
        if (employees == null || employees.isEmpty()) return;

        List<com.bionova.entity.CompanyMaster> companies = companyRepository.findAll();
        Map<Long, String> coyMap = companies.stream()
            .collect(java.util.stream.Collectors.toMap(
                com.bionova.entity.CompanyMaster::getCoyId,
                com.bionova.entity.CompanyMaster::getCoyNm,
                (v1, v2) -> v1
            ));

        List<com.bionova.entity.PlantMaster> plants = plantRepository.findAll();
        Map<Long, String> pltMap = plants.stream()
            .collect(java.util.stream.Collectors.toMap(
                com.bionova.entity.PlantMaster::getPltId,
                com.bionova.entity.PlantMaster::getPltNm,
                (v1, v2) -> v1
            ));

        List<com.bionova.entity.DepartmentMaster> departments = departmentRepository.findAll();
        Map<Long, String> deptMap = departments.stream()
            .collect(java.util.stream.Collectors.toMap(
                com.bionova.entity.DepartmentMaster::getDeptId,
                com.bionova.entity.DepartmentMaster::getDeptNm,
                (v1, v2) -> v1
            ));

        // Build a name map for reporting managers from the same employees list
        Map<Long, String> empNameMap = employees.stream()
            .collect(java.util.stream.Collectors.toMap(
                Employee::getEmpId,
                e -> ((e.getFirstName() != null ? e.getFirstName() : "") + " " +
                      (e.getLastName() != null ? e.getLastName() : "")).trim(),
                (v1, v2) -> v1
            ));

        for (Employee emp : employees) {
            if (emp.getCoyId() != null) {
                emp.setCoyNm(coyMap.get(emp.getCoyId().longValue()));
            }
            if (emp.getPltId() != null) {
                emp.setPltNm(pltMap.get(emp.getPltId().longValue()));
            }
            if (emp.getDeptId() != null) {
                emp.setDeptNm(deptMap.get(emp.getDeptId().longValue()));
            }
            if (emp.getRepManId() != null) {
                String mgrName = empNameMap.get(emp.getRepManId().longValue());
                if (mgrName != null && !mgrName.isBlank()) {
                    emp.setRepManNm(mgrName);
                }
            }
        }
    }

    @GetMapping("/employees")
    public List<Employee> getEmployees() {
        List<Employee> list = employeeRepository.findAll();
        populateDesignations(list);
        populateCompanyAndPlantNames(list);
        return list;
    }

    @GetMapping("/employees/{id}")
    public ResponseEntity<Employee> getEmployeeById(@PathVariable Long id) {
        return employeeRepository.findById(id)
                .map(emp -> {
                    populateDesignation(emp);
                    populateCompanyAndPlant(emp);
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
                    populateCompanyAndPlant(emp);
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

    @PostMapping("/employees/change-password")
    public ResponseEntity<?> changePassword(@RequestBody Map<String, String> request) {
        String currentPassword = request.get("currentPassword");
        String newPassword = request.get("newPassword");

        if (currentPassword == null || currentPassword.isEmpty() || newPassword == null || newPassword.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Current password and new password are required."));
        }

        if (newPassword.length() < 8) {
            return ResponseEntity.badRequest().body(Map.of("message", "Password must be at least 8 characters long."));
        }

        String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> {
                    org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder encoder = 
                            new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder();
                    
                    if (!encoder.matches(currentPassword, employee.getPassword())) {
                        return ResponseEntity.badRequest().body(Map.of("message", "Incorrect current password."));
                    }
                    
                    employee.setPassword(encoder.encode(newPassword));
                    employeeRepository.save(employee);
                    return ResponseEntity.ok(Map.of("message", "Password updated successfully."));
                })
                .orElse(ResponseEntity.status(401).body(Map.of("message", "Employee not found.")));
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
        populateCompanyAndPlant(saved);
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
        populateCompanyAndPlant(updated);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/employees/{id}")
    public ResponseEntity<?> deleteEmployee(@PathVariable Long id) {
        employeeRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
