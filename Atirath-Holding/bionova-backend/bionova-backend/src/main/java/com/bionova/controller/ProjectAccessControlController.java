package com.bionova.controller;

import com.bionova.dto.ProjectAccessControlResponseDto;
import com.bionova.service.ProjectAccessControlService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/project-access-control")
public class ProjectAccessControlController {

    @Autowired
    private ProjectAccessControlService pacService;

    @GetMapping("/{prjId}")
    public ResponseEntity<?> getProjectAccessControl(@PathVariable Long prjId) {
        try {
            ProjectAccessControlResponseDto response = pacService.getProjectAccessControl(prjId);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "An unexpected error occurred: " + e.getMessage()));
        }
    }
}
