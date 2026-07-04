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

    /**
     * Returns whether RBAC has been configured for the given employee.
     * Frontend uses this to decide: show all menus (no RBAC) vs. show filtered menus (RBAC set).
     */
    @GetMapping("/employees/{empId}/has-rbac")
    public ResponseEntity<Map<String, Object>> hasRbac(@PathVariable Long empId) {
        boolean hasRbac = rbacService.hasRbacConfigured(empId);
        return ResponseEntity.ok(Map.of("hasRbac", hasRbac, "empId", empId));
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

    @PostMapping("/roles")
    public ResponseEntity<?> saveRole(@RequestBody com.bionova.dto.SaveRoleRequest request) {
        try {
            rbacService.saveRole(request.getRoleNm(), request.getPermissions(), request.getCreatedBy());
            return ResponseEntity.ok(Map.of("message", "Role template saved successfully."));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Failed to save role: " + e.getMessage()));
        }
    }

    @PutMapping("/roles/{roleId}")
    public ResponseEntity<?> updateRole(@PathVariable Integer roleId, @RequestBody com.bionova.dto.SaveRoleRequest request) {
        try {
            rbacService.updateRole(roleId, request.getRoleNm(), request.getPermissions(), request.getCreatedBy());
            return ResponseEntity.ok(Map.of("message", "Role template updated successfully."));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Failed to update role: " + e.getMessage()));
        }
    }

    @DeleteMapping("/roles/{roleId}")
    public ResponseEntity<?> deleteRole(@PathVariable Integer roleId) {
        try {
            rbacService.deleteRole(roleId);
            return ResponseEntity.ok(Map.of("message", "Role template deleted successfully."));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("message", "Failed to delete role: " + e.getMessage()));
        }
    }
}
