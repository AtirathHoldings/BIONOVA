package com.bionova.controller;

import com.bionova.dto.AdminDashboardResponse;
import com.bionova.service.AdminDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class AdminDashboardController {

    @Autowired
    private AdminDashboardService adminDashboardService;

    /**
     * Retrieves the metrics and statistical summaries for the admin dashboard.
     * Secured by default; requires a valid JWT token.
     */
    @GetMapping("/admin/dashboard/metrics")
    public ResponseEntity<AdminDashboardResponse> getDashboardMetrics() {
        AdminDashboardResponse data = adminDashboardService.getDashboardData();
        return ResponseEntity.ok(data);
    }
}
