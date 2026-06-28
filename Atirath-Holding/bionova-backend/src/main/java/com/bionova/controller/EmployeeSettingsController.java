package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.entity.EmployeeSettings;
import com.bionova.dto.EmployeeSettingsResponseDto;
import com.bionova.repository.EmployeeRepository;
import com.bionova.service.EmployeeSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/settings")
public class EmployeeSettingsController {

    @Autowired
    private EmployeeSettingsService settingsService;

    @Autowired
    private EmployeeRepository employeeRepository;

    @GetMapping
    public ResponseEntity<?> getSettings() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);

        if (employee == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Unauthorized or Employee not found."));
        }

        EmployeeSettingsResponseDto data = settingsService.getSettings(employee.getEmpId());
        return ResponseEntity.ok(data);
    }

    @PutMapping
    public ResponseEntity<?> updateSettings(@RequestBody EmployeeSettings settings) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);

        if (employee == null) {
            return ResponseEntity.status(401).body(Map.of("message", "Unauthorized or Employee not found."));
        }

        EmployeeSettings updated = settingsService.updateSettings(employee.getEmpId(), settings);
        return ResponseEntity.ok(updated);
    }
}
