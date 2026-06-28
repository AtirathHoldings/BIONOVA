package com.bionova.controller;

import com.bionova.dto.ScreenPermissionDto;
import com.bionova.dto.SaveAccessRequest;
import com.bionova.dto.RoleDto;
import com.bionova.entity.ScreenMaster;
import com.bionova.service.RbacService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/rbac")
public class RbacController {

    @Autowired
    private RbacService rbacService;

    @GetMapping("/screens")
    public List<ScreenMaster> getScreens() {
        return rbacService.getAllScreens();
    }

    @GetMapping("/roles")
    public List<RoleDto> getRoles() {
        return rbacService.getAllRoles();
    }

    @GetMapping("/roles/{roleId}/permissions")
    public List<ScreenPermissionDto> getRolePermissions(@PathVariable Integer roleId) {
        return rbacService.getRolePermissions(roleId);
    }

    @GetMapping("/employees/{empId}/permissions")
    public List<ScreenPermissionDto> getEmployeePermissions(@PathVariable Long empId) {
        return rbacService.getEmployeePermissions(empId);
    }

    @PostMapping("/save")
    public ResponseEntity<?> saveAccess(@RequestBody SaveAccessRequest request) {
        try {
            rbacService.saveAccess(request);
            return ResponseEntity.ok(Map.of("message", "Access configuration saved successfully."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Failed to save access: " + e.getMessage()));
        }
    }
}
