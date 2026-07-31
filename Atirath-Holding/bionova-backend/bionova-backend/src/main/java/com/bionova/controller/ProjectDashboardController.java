package com.bionova.controller;

import com.bionova.dto.ProjectDashboardResponse;
import com.bionova.service.ProjectDashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
public class ProjectDashboardController {

    @Autowired
    private ProjectDashboardService projectDashboardService;

    @GetMapping("/project-manager-metrics")
    public ResponseEntity<ProjectDashboardResponse> getProjectManagerMetrics() {
        ProjectDashboardResponse response = projectDashboardService.getProjectManagerMetrics();
        return ResponseEntity.ok(response);
    }
}
