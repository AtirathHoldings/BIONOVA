package com.bionova.controller;

import com.bionova.entity.ExternalEmployee;
import com.bionova.repository.ExternalEmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ExternalEmployeeController {

    @Autowired
    private ExternalEmployeeRepository externalEmployeeRepository;

    @GetMapping("/external-employees")
    public List<ExternalEmployee> getExternalEmployees() {
        return externalEmployeeRepository.findAll();
    }

    @PostMapping("/external-employees")
    public ResponseEntity<?> saveExternalEmployee(@RequestBody ExternalEmployee employee) {
        if (employee.getMobNum() != null && employee.getMobNum().trim().isEmpty()) {
            employee.setMobNum(null);
        }
        if (employee.getEmail() != null && employee.getEmail().trim().isEmpty()) {
            employee.setEmail(null);
        }
        if (employee.getPhotoPath() != null && employee.getPhotoPath().trim().isEmpty()) {
            employee.setPhotoPath(null);
        }

        if (employee.getExtEmpCode() == null || employee.getExtEmpCode().trim().isEmpty()) {
            List<ExternalEmployee> all = externalEmployeeRepository.findAll();
            int max = 0;
            for (ExternalEmployee e : all) {
                if (e.getExtEmpCode() != null && e.getExtEmpCode().matches("(?i)EXT-\\d+")) {
                    try {
                        int n = Integer.parseInt(e.getExtEmpCode().replaceAll("[^0-9]", ""));
                        if (n > max) max = n;
                    } catch (NumberFormatException ignored) {}
                }
            }
            employee.setExtEmpCode(String.format("EXT-%03d", max + 1));
        }

        if (externalEmployeeRepository.existsByExtEmpCode(employee.getExtEmpCode())) {
            return ResponseEntity.badRequest().body(Map.of("message", "External employee code already exists (" + employee.getExtEmpCode() + ")."));
        }
        if (employee.getEmail() != null && !employee.getEmail().trim().isEmpty() &&
                externalEmployeeRepository.existsByEmail(employee.getEmail())) {
            return ResponseEntity.badRequest().body(Map.of("message", "External employee email already exists."));
        }
        if (employee.getMobNum() != null && !employee.getMobNum().trim().isEmpty() &&
                externalEmployeeRepository.existsByMobNum(employee.getMobNum())) {
            return ResponseEntity.badRequest().body(Map.of("message", "External employee mobile number already exists."));
        }

        ExternalSecurityHelper.checkDefaultStatus(employee);

        try {
            ExternalEmployee saved = externalEmployeeRepository.save(employee);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("message", "Failed to save external employee: " + e.getMessage()));
        }
    }

    @PutMapping("/external-employees/{id}")
    public ResponseEntity<?> updateExternalEmployee(@PathVariable Long id, @RequestBody ExternalEmployee employeeDetails) {
        ExternalEmployee employee = externalEmployeeRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("External employee not found with id: " + id));

        if (employeeDetails.getExtEmpCode() != null && !employeeDetails.getExtEmpCode().trim().isEmpty() &&
                externalEmployeeRepository.existsByExtEmpCodeAndExtEmpIdNot(employeeDetails.getExtEmpCode(), id)) {
            return ResponseEntity.badRequest().body(Map.of("message", "External employee code already exists."));
        }
        if (employeeDetails.getEmail() != null && !employeeDetails.getEmail().trim().isEmpty() &&
                externalEmployeeRepository.existsByEmailAndExtEmpIdNot(employeeDetails.getEmail(), id)) {
            return ResponseEntity.badRequest().body(Map.of("message", "External employee email already exists."));
        }
        if (employeeDetails.getMobNum() != null && !employeeDetails.getMobNum().trim().isEmpty() &&
                externalEmployeeRepository.existsByMobNumAndExtEmpIdNot(employeeDetails.getMobNum(), id)) {
            return ResponseEntity.badRequest().body(Map.of("message", "External employee mobile number already exists."));
        }

        employee.setExtEmpCode(employeeDetails.getExtEmpCode());
        employee.setExtEmpNm(employeeDetails.getExtEmpNm());
        employee.setEmail(employeeDetails.getEmail());
        employee.setMobNum(employeeDetails.getMobNum());
        employee.setCompanyNm(employeeDetails.getCompanyNm());
        employee.setPhotoPath(employeeDetails.getPhotoPath());
        employee.setRepEmpId(employeeDetails.getRepEmpId());
        
        if (employeeDetails.getSts() != null) {
            employee.setSts(employeeDetails.getSts());
        }

        ExternalEmployee updated = externalEmployeeRepository.save(employee);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/external-employees/{id}")
    public ResponseEntity<?> deleteExternalEmployee(@PathVariable Long id) {
        externalEmployeeRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    private static class ExternalSecurityHelper {
        public static void checkDefaultStatus(ExternalEmployee employee) {
            if (employee.getSts() == null) {
                employee.setSts(true);
            }
        }
    }
}
