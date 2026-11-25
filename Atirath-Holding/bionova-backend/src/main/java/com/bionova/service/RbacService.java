package com.bionova.service;

import com.bionova.dto.ScreenPermissionDto;
import com.bionova.dto.SaveAccessRequest;
import com.bionova.dto.RoleDto;
import com.bionova.dto.EmployeePermissionsDto;
import com.bionova.dto.UpdateEmployeePermissionsRequest;
import com.bionova.entity.*;
import com.bionova.repository.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class RbacService {

    @Autowired
    private ScreenMasterRepository screenMasterRepository;

    @Autowired
    private RoleBasedAccessControlRepository rbacRepository;

    @Autowired
    private RoleBasedEmployeeMappingRepository employeeMappingRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private DesignationRepository designationRepository;


    public List<ScreenMaster> getAllScreens() {
        ensureOperationalScreens();
        return screenMasterRepository.findAll();
    }

    private void ensureOperationalScreens() {
        try {
            ensureScreen("PROCUREMENT_MANAGEMENT", "Procurement & PO Management", "Supply Chain & Operations");
            ensureScreen("ASSET_MAINTENANCE", "Equipment & Asset Maintenance (CMMS)", "Supply Chain & Operations");
            ensureScreen("FLEET_DISPATCH", "Fleet & Dispatch Logistics", "Supply Chain & Operations");
            ensureScreen("INVENTORY_MANAGEMENT", "Inventory Management", "Operations");
            ensureScreen("VISITOR_MANAGEMENT", "Visitor Management", "Operations");
            ensureScreen("EXECUTIVE_MODULE", "Executive Overview", "Executive");
            ensureScreen("HARVESTING_MODULE", "Harvesting & Feedstock Batches", "Operations");
            ensureScreen("DPR_MANAGEMENT", "Daily Progress Report (DPR)", "Operations");
        } catch (Exception e) {
            // Silently continue if DB temporarily read-only
        }
    }

    private void ensureScreen(String code, String name, String group) {
        if (screenMasterRepository.findByScreenCode(code).isEmpty()) {
            ScreenMaster sm = new ScreenMaster();
            sm.setScreenCode(code);
            sm.setScreenNm(name);
            sm.setGroupNm(group);
            screenMasterRepository.save(sm);
        }
    }

    public List<RoleDto> getAllRoles() {
        // Filter out employee-specific custom roles from templates dropdown lists
        return rbacRepository.findDistinctRoles().stream()
                .filter(r -> r.getRoleNm() != null && !r.getRoleNm().startsWith("Custom_"))
                .collect(Collectors.toList());
    }

    /**
     * Returns true if the employee has at least one RBAC mapping in the database.
     * When false â†’ no RBAC configured yet â†’ show all screens (full_access mode).
     * When true  â†’ RBAC is set up â†’ filter screens based on permissions.
     */
    @Cacheable(value = "rbacHasRbac", key = "#empId")
    public boolean hasRbacConfigured(Long empId) {
        return !employeeMappingRepository.findByEmpId(empId).isEmpty();
    }

    public List<ScreenPermissionDto> getRolePermissions(Integer roleId) {
        List<ScreenMaster> screens = screenMasterRepository.findAll();
        List<RoleBasedAccessControl> mapped = rbacRepository.findByRoleId(roleId);
        Map<Integer, RoleBasedAccessControl> map = mapped.stream()
                .collect(Collectors.toMap(RoleBasedAccessControl::getScreenId, r -> r));

        return screens.stream().map(screen -> {
            RoleBasedAccessControl rbac = map.get(screen.getScreenId());
            ScreenPermissionDto dto = new ScreenPermissionDto();
            dto.setScreenId(screen.getScreenId());
            dto.setScreenNm(screen.getScreenNm());
            dto.setGroupNm(screen.getGroupNm());
            dto.setScreenCode(screen.getScreenCode());
            if (rbac != null) {
                dto.setViewFlg(rbac.getViewFlg());
                dto.setEditFlg(rbac.getEditFlg());
                dto.setAddFlg(rbac.getAddFlg());
                dto.setDeleteFlg(rbac.getDeleteFlg());
                dto.setAccessType("From Template");
            } else {
                dto.setViewFlg(false);
                dto.setEditFlg(false);
                dto.setAddFlg(false);
                dto.setDeleteFlg(false);
                dto.setAccessType("None");
            }
            return dto;
        }).collect(Collectors.toList());
    }

    @Cacheable(value = "rbacPermissions", key = "#empId")
    public List<ScreenPermissionDto> getEmployeePermissions(Long empId) {
        List<RoleBasedEmployeeMapping> mappings = employeeMappingRepository.findByEmpId(empId);
        if (mappings.isEmpty()) {
            return getRolePermissions(-1);
        }

        List<ScreenPermissionDto> aggregated = null;
        for (RoleBasedEmployeeMapping mapping : mappings) {
            List<ScreenPermissionDto> rolePerms = getRolePermissions(mapping.getRoleId());
            if (aggregated == null) {
                aggregated = new ArrayList<>();
                for (ScreenPermissionDto rp : rolePerms) {
                    ScreenPermissionDto copy = new ScreenPermissionDto(
                        rp.getScreenId(), rp.getScreenNm(), rp.getGroupNm(), rp.getScreenCode(),
                        rp.getViewFlg(), rp.getEditFlg(), rp.getAddFlg(), rp.getDeleteFlg(), rp.getAccessType()
                    );
                    aggregated.add(copy);
                }
            } else {
                for (int i = 0; i < aggregated.size(); i++) {
                    ScreenPermissionDto agg = aggregated.get(i);
                    ScreenPermissionDto roleP = rolePerms.get(i);
                    agg.setViewFlg(agg.getViewFlg() || roleP.getViewFlg());
                    agg.setEditFlg(agg.getEditFlg() || roleP.getEditFlg());
                    agg.setAddFlg(agg.getAddFlg() || roleP.getAddFlg());
                    agg.setDeleteFlg(agg.getDeleteFlg() || roleP.getDeleteFlg());
                }
            }
        }
        return aggregated;
    }

    @Transactional
    @CacheEvict(value = {"rbacHasRbac", "rbacPermissions"}, allEntries = true)
    public void saveAccess(SaveAccessRequest request) {
        if (request.getEmpIds() == null || request.getEmpIds().isEmpty()) {
            throw new IllegalArgumentException("At least one employee must be selected.");
        }

        Integer finalRoleId = request.getRoleId();
        String finalRoleNm = null;

        // Determine if there are overrides or if saving as a template
        if (request.getCustomRoleName() != null && !request.getCustomRoleName().trim().isEmpty()) {
            // Save as a new named template role
            finalRoleNm = request.getCustomRoleName().trim();
            finalRoleId = rbacRepository.findMaxRoleId() + 1;
            savePermissionsForRole(finalRoleId, finalRoleNm, request.getPermissions(), request.getCreatedBy());
        } 
        else if (hasOverrides(request.getRoleId(), request.getPermissions())) {
            // Check if it matches any existing template role
            Integer matchedRoleId = null;
            String matchedRoleNm = null;
            List<RoleDto> allRoles = getAllRoles();
            for (RoleDto role : allRoles) {
                if (!hasOverrides(role.getRoleId(), request.getPermissions())) {
                    matchedRoleId = role.getRoleId();
                    matchedRoleNm = role.getRoleNm();
                    break;
                }
            }

            if (matchedRoleId != null) {
                finalRoleId = matchedRoleId;
                finalRoleNm = matchedRoleNm;
            } else {
                // Save as an ad-hoc custom override role specific to this configuration
                finalRoleNm = "Custom_Access_" + System.currentTimeMillis();
                Integer maxId = rbacRepository.findMaxRoleId();
                finalRoleId = (maxId == null ? 0 : maxId) + 1;
                savePermissionsForRole(finalRoleId, finalRoleNm, request.getPermissions(), request.getCreatedBy());
            }
        } else if (request.getRoleId() != null) {
            // Just use the base template role, find its name
            List<RoleBasedAccessControl> existing = rbacRepository.findByRoleId(request.getRoleId());
            if (!existing.isEmpty()) {
                finalRoleNm = existing.get(0).getRoleNm();
            }
        }

        if (finalRoleId != null) {
            for (Long empId : request.getEmpIds()) {
                employeeMappingRepository.deleteByEmpId(empId);

                RoleBasedEmployeeMapping mapping = new RoleBasedEmployeeMapping();
                mapping.setEmpId(empId);
                mapping.setRoleId(finalRoleId);
                employeeMappingRepository.save(mapping);
            }
        }
    }

    private void savePermissionsForRole(Integer roleId, String roleNm, List<ScreenPermissionDto> permissions, String createdBy) {
        if (permissions == null) return;
        final String creator = (createdBy == null || createdBy.trim().isEmpty()) ? "Admin" : createdBy;
        List<RoleBasedAccessControl> rbacs = permissions.stream().map(p -> {
            RoleBasedAccessControl r = new RoleBasedAccessControl();
            r.setRoleId(roleId);
            r.setRoleNm(roleNm);
            r.setScreenId(p.getScreenId());
            r.setViewFlg(p.getViewFlg() != null && p.getViewFlg());
            r.setEditFlg(p.getEditFlg() != null && p.getEditFlg());
            r.setAddFlg(p.getAddFlg() != null && p.getAddFlg());
            r.setDeleteFlg(p.getDeleteFlg() != null && p.getDeleteFlg());
            r.setCreatedBy(creator);
            return r;
        }).collect(Collectors.toList());
        rbacRepository.saveAll(rbacs);
    }

    @Transactional
    public void saveRole(String roleNm, List<ScreenPermissionDto> permissions, String createdBy) {
        Integer finalRoleId = rbacRepository.findMaxRoleId() + 1;
        savePermissionsForRole(finalRoleId, roleNm, permissions, createdBy);
    }

    @Transactional
    public void updateRole(Integer roleId, String roleNm, List<ScreenPermissionDto> permissions, String createdBy) {
        String name = roleNm;
        if (name == null || name.trim().isEmpty()) {
            List<RoleBasedAccessControl> existing = rbacRepository.findByRoleId(roleId);
            if (!existing.isEmpty()) {
                name = existing.get(0).getRoleNm();
            } else {
                name = "Role_" + roleId;
            }
        }
        rbacRepository.deleteByRoleId(roleId);
        savePermissionsForRole(roleId, name, permissions, createdBy);
    }

    @Transactional
    public void deleteRole(Integer roleId) {
        rbacRepository.deleteByRoleId(roleId);
        List<RoleBasedEmployeeMapping> mappings = employeeMappingRepository.findByRoleId(roleId);
        if (!mappings.isEmpty()) {
            employeeMappingRepository.deleteAll(mappings);
        }
    }

    private boolean hasOverrides(Integer baseRoleId, List<ScreenPermissionDto> requested) {
        if (baseRoleId == null || requested == null) return true;
        List<ScreenPermissionDto> base = getRolePermissions(baseRoleId);
        if (base.size() != requested.size()) return true;

        Map<Integer, ScreenPermissionDto> baseMap = base.stream()
                .collect(Collectors.toMap(ScreenPermissionDto::getScreenId, p -> p));

        for (ScreenPermissionDto req : requested) {
            ScreenPermissionDto b = baseMap.get(req.getScreenId());
            if (b == null) return true;
            if (!Objects.equals(b.getViewFlg(), req.getViewFlg()) ||
                !Objects.equals(b.getEditFlg(), req.getEditFlg()) ||
                !Objects.equals(b.getAddFlg(), req.getAddFlg()) ||
                !Objects.equals(b.getDeleteFlg(), req.getDeleteFlg())) {
                return true;
            }
        }
        return false;
    }
    public List<EmployeePermissionsDto> getAllEmployeePermissions() {
        List<RoleBasedEmployeeMapping> allMappings = employeeMappingRepository.findAll();
        Set<Long> empIds = allMappings.stream()
                .map(RoleBasedEmployeeMapping::getEmpId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        Map<Integer, String> designationMap = designationRepository.findAll().stream()
                .collect(Collectors.toMap(
                        DesignationMaster::getDesigId,
                        DesignationMaster::getDesigNm,
                        (a, b) -> a
                ));

        List<EmployeePermissionsDto> result = new ArrayList<>();
        for (Long empId : empIds) {
            Optional<Employee> empOpt = employeeRepository.findById(empId);
            if (empOpt.isPresent()) {
                Employee employee = empOpt.get();
                String name = (employee.getFirstName() + " " + (employee.getLastName() == null ? "" : employee.getLastName())).trim();
                String desigName = employee.getDesigId() != null ? designationMap.get(employee.getDesigId()) : null;
                if (desigName == null) {
                    desigName = employee.getRole() != null ? employee.getRole() : "Employee";
                }

                List<ScreenPermissionDto> permissions = getEmployeePermissions(empId);

                EmployeePermissionsDto dto = new EmployeePermissionsDto(
                        empId,
                        name,
                        employee.getEmail(),
                        employee.getEmpCode(),
                        desigName,
                        permissions
                );
                result.add(dto);
            }
        }
        return result;
    }

    @Transactional
    @CacheEvict(value = {"rbacHasRbac", "rbacPermissions"}, allEntries = true)
    public void updateEmployeePermissions(Long empId, UpdateEmployeePermissionsRequest request) {
        List<RoleBasedEmployeeMapping> oldMappings = employeeMappingRepository.findByEmpId(empId);

        Integer finalRoleId = null;
        String finalRoleNm = null;

        // Check if the requested permissions match any existing template role
        List<RoleDto> allRoles = getAllRoles();
        for (RoleDto role : allRoles) {
            if (!hasOverrides(role.getRoleId(), request.getPermissions())) {
                finalRoleId = role.getRoleId();
                finalRoleNm = role.getRoleNm();
                break;
            }
        }

        // If no match is found, create a new custom role
        if (finalRoleId == null) {
            if (request.getCustomRoleName() != null && !request.getCustomRoleName().trim().isEmpty()) {
                finalRoleNm = request.getCustomRoleName().trim();
            } else {
                finalRoleNm = "Custom_Access_" + System.currentTimeMillis();
            }
            Integer maxId = rbacRepository.findMaxRoleId();
            finalRoleId = (maxId == null ? 0 : maxId) + 1;
            savePermissionsForRole(finalRoleId, finalRoleNm, request.getPermissions(), request.getCreatedBy());
        }

        employeeMappingRepository.deleteByEmpId(empId);

        RoleBasedEmployeeMapping newMapping = new RoleBasedEmployeeMapping();
        newMapping.setEmpId(empId);
        newMapping.setRoleId(finalRoleId);
        employeeMappingRepository.save(newMapping);

        // Clean up old custom roles
        for (RoleBasedEmployeeMapping oldMapping : oldMappings) {
            Integer oldRoleId = oldMapping.getRoleId();
            if (oldRoleId.equals(finalRoleId)) continue;

            List<RoleBasedAccessControl> rbacList = rbacRepository.findByRoleId(oldRoleId);
            if (!rbacList.isEmpty()) {
                String oldRoleNm = rbacList.get(0).getRoleNm();
                if (oldRoleNm != null && oldRoleNm.startsWith("Custom_")) {
                    List<RoleBasedEmployeeMapping> remaining = employeeMappingRepository.findByRoleId(oldRoleId);
                    if (remaining.isEmpty()) {
                        rbacRepository.deleteByRoleId(oldRoleId);
                    }
                }
            }
        }
    }

    @Transactional
    public void deleteEmployeeAccess(Long empId) {
        List<RoleBasedEmployeeMapping> oldMappings = employeeMappingRepository.findByEmpId(empId);

        employeeMappingRepository.deleteByEmpId(empId);

        // Clean up old custom roles
        for (RoleBasedEmployeeMapping oldMapping : oldMappings) {
            Integer oldRoleId = oldMapping.getRoleId();
            List<RoleBasedAccessControl> rbacList = rbacRepository.findByRoleId(oldRoleId);
            if (!rbacList.isEmpty()) {
                String oldRoleNm = rbacList.get(0).getRoleNm();
                if (oldRoleNm != null && oldRoleNm.startsWith("Custom_")) {
                    List<RoleBasedEmployeeMapping> remaining = employeeMappingRepository.findByRoleId(oldRoleId);
                    if (remaining.isEmpty()) {
                        rbacRepository.deleteByRoleId(oldRoleId);
                    }
                }
            }
        }
    }

    public String determineLandingRoute(Long empId, String role) {
        if (role != null) {
            String lower = role.toLowerCase().trim();
            if ("admin".equals(lower) || "super_admin".equals(lower) || "full_access".equals(lower)) {
                return "/dashboard";
            }
        }

        if (empId == null) {
            return "/user-dashboard";
        }

        List<ScreenPermissionDto> perms = getEmployeePermissions(empId);
        if (perms == null || perms.isEmpty()) {
            return "/user-dashboard";
        }

        List<ScreenPermissionDto> allowed = perms.stream()
                .filter(p -> Boolean.TRUE.equals(p.getViewFlg()))
                .collect(Collectors.toList());

        if (allowed.isEmpty()) {
            return "/user-dashboard";
        }

        // 1. If Admin Dashboard is allowed
        if (allowed.stream().anyMatch(p -> "ADMIN_DASHBOARD".equalsIgnoreCase(p.getScreenCode()))) {
            return "/dashboard";
        }

        // Check if role name hints at specific module
        String lowerRole = (role != null) ? role.toLowerCase() : "";
        List<RoleBasedEmployeeMapping> mappings = employeeMappingRepository.findByEmpId(empId);
        if (!mappings.isEmpty()) {
            List<RoleBasedAccessControl> rbacList = rbacRepository.findByRoleId(mappings.get(0).getRoleId());
            if (!rbacList.isEmpty() && rbacList.get(0).getRoleNm() != null) {
                lowerRole = rbacList.get(0).getRoleNm().toLowerCase();
            }
        }

        // If the role explicitly specifies one of the operational modules:
        if (lowerRole.contains("inventory") && allowed.stream().anyMatch(p -> "INVENTORY_MANAGEMENT".equalsIgnoreCase(p.getScreenCode()))) {
            return "/inventory";
        }
        if (lowerRole.contains("visitor") && allowed.stream().anyMatch(p -> "VISITOR_MANAGEMENT".equalsIgnoreCase(p.getScreenCode()))) {
            return "/visitor-management";
        }
        if (lowerRole.contains("executive") && allowed.stream().anyMatch(p -> "EXECUTIVE_MODULE".equalsIgnoreCase(p.getScreenCode()))) {
            return "/executive";
        }
        if ((lowerRole.contains("procurement") || lowerRole.contains("supply")) && allowed.stream().anyMatch(p -> "PROCUREMENT_MANAGEMENT".equalsIgnoreCase(p.getScreenCode()))) {
            return "/procurement";
        }
        if (lowerRole.contains("asset") && allowed.stream().anyMatch(p -> "ASSET_MAINTENANCE".equalsIgnoreCase(p.getScreenCode()))) {
            return "/asset-maintenance";
        }
        if (lowerRole.contains("dispatch") && allowed.stream().anyMatch(p -> "FLEET_DISPATCH".equalsIgnoreCase(p.getScreenCode()))) {
            return "/dispatch-logistics";
        }
        if (lowerRole.contains("harvest") && allowed.stream().anyMatch(p -> "HARVESTING_MODULE".equalsIgnoreCase(p.getScreenCode()) || "HARVESTING".equalsIgnoreCase(p.getScreenCode()))) {
            return "/harvesting";
        }
        if (lowerRole.contains("dpr") && allowed.stream().anyMatch(p -> "DPR_MANAGEMENT".equalsIgnoreCase(p.getScreenCode()) || "DPR".equalsIgnoreCase(p.getScreenCode()))) {
            return "/dpr";
        }

        // Check if user has User Dashboard or Project Dashboard
        boolean hasUserDash = allowed.stream().anyMatch(p -> "USER_DASHBOARD".equalsIgnoreCase(p.getScreenCode()));
        boolean hasPmDash = allowed.stream().anyMatch(p -> "PROJECT_DASHBOARD".equalsIgnoreCase(p.getScreenCode()) || "PROJECT_CREATION".equalsIgnoreCase(p.getScreenCode()));

        // If user does NOT have User Dashboard and does NOT have Project Dashboard, check operational modules:
        if (!hasUserDash && !hasPmDash) {
            if (allowed.stream().anyMatch(p -> "INVENTORY_MANAGEMENT".equalsIgnoreCase(p.getScreenCode()))) {
                return "/inventory";
            }
            if (allowed.stream().anyMatch(p -> "VISITOR_MANAGEMENT".equalsIgnoreCase(p.getScreenCode()))) {
                return "/visitor-management";
            }
            if (allowed.stream().anyMatch(p -> "EXECUTIVE_MODULE".equalsIgnoreCase(p.getScreenCode()))) {
                return "/executive";
            }
            if (allowed.stream().anyMatch(p -> "PROCUREMENT_MANAGEMENT".equalsIgnoreCase(p.getScreenCode()))) {
                return "/procurement";
            }
            if (allowed.stream().anyMatch(p -> "ASSET_MAINTENANCE".equalsIgnoreCase(p.getScreenCode()))) {
                return "/asset-maintenance";
            }
            if (allowed.stream().anyMatch(p -> "FLEET_DISPATCH".equalsIgnoreCase(p.getScreenCode()))) {
                return "/dispatch-logistics";
            }
            if (allowed.stream().anyMatch(p -> "HARVESTING_MODULE".equalsIgnoreCase(p.getScreenCode()) || "HARVESTING".equalsIgnoreCase(p.getScreenCode()))) {
                return "/harvesting";
            }
            if (allowed.stream().anyMatch(p -> "DPR_MANAGEMENT".equalsIgnoreCase(p.getScreenCode()) || "DPR".equalsIgnoreCase(p.getScreenCode()))) {
                return "/dpr";
            }
            for (ScreenPermissionDto p : allowed) {
                String route = mapScreenCodeToRoute(p.getScreenCode());
                if (route != null) {
                    return route;
                }
            }
        }

        // If user has Project Dashboard
        if (hasPmDash && (lowerRole.contains("pm") || lowerRole.contains("project") || lowerRole.contains("manager") || !hasUserDash)) {
            return "/pm-dashboard";
        }

        // If user has User Dashboard
        if (hasUserDash) {
            return "/user-dashboard";
        }

        // Fallback to first allowed screen or user-dashboard
        for (ScreenPermissionDto p : allowed) {
            String route = mapScreenCodeToRoute(p.getScreenCode());
            if (route != null) {
                return route;
            }
        }

        return "/user-dashboard";
    }

    public String determineDefaultScreenCode(Long empId, String role) {
        String route = determineLandingRoute(empId, role);
        if ("/dashboard".equals(route)) return "ADMIN_DASHBOARD";
        if ("/pm-dashboard".equals(route)) return "PROJECT_DASHBOARD";
        if ("/user-dashboard".equals(route)) return "USER_DASHBOARD";
        if ("/inventory".equals(route)) return "INVENTORY_MANAGEMENT";
        if ("/visitor-management".equals(route)) return "VISITOR_MANAGEMENT";
        if ("/executive".equals(route)) return "EXECUTIVE_MODULE";
        if ("/procurement".equals(route)) return "PROCUREMENT_MANAGEMENT";
        if ("/asset-maintenance".equals(route)) return "ASSET_MAINTENANCE";
        if ("/dispatch-logistics".equals(route)) return "FLEET_DISPATCH";
        if ("/harvesting".equals(route)) return "HARVESTING_MODULE";
        if ("/dpr".equals(route)) return "DPR_MANAGEMENT";
        return "USER_DASHBOARD";
    }

    public String mapScreenCodeToRoute(String screenCode) {
        if (screenCode == null) return "/user-dashboard";
        switch (screenCode.toUpperCase()) {
            case "ADMIN_DASHBOARD": return "/dashboard";
            case "COMPANY_CREATION": return "/company-creation";
            case "PLANT_CREATION": return "/plant-creation";
            case "LAND_CREATION": return "/agriland-allocation";
            case "DEPARTMENT_CREATION": return "/department-creation";
            case "DEPARTMENT_MAPPING": return "/department-mapping";
            case "DESIGNATION_CREATION": return "/designation-creation";
            case "EMPLOYEE_CREATION": return "/employee-creation";
            case "PROJECT_CREATION": return "/project-creation";
            case "MILESTONE_CREATION": return "/milestone-creation";
            case "PROJECT_DASHBOARD": return "/pm-dashboard";
            case "TASK_BOARD": return "/task-board";
            case "GANTT_CHART":
            case "ALL_PROJECT_GANTT_CHART": return "/all-project-gantt-chart";
            case "USER_DASHBOARD": return "/user-dashboard";
            case "MY_TASK": return "/my-tasks";
            case "MY_PROJECTS": return "/projects";
            case "CALENDAR": return "/calendar";
            case "USER_TASK_BOARD": return "/user-task-board";
            case "PUBLIC_HOLIDAYS": return "/public-holidays";
            case "PROFILE": return "/profile";
            case "INDIVIDUAL_TASK": return "/assignment";
            case "ASSIGN_ACCESS": return "/assign-access";
            case "PROJECT_ACCESS": return "/project-access";
            case "INVENTORY_MANAGEMENT": return "/inventory";
            case "VISITOR_MANAGEMENT": return "/visitor-management";
            case "EXECUTIVE_MODULE": return "/executive";
            case "PROCUREMENT_MANAGEMENT": return "/procurement";
            case "ASSET_MAINTENANCE": return "/asset-maintenance";
            case "FLEET_DISPATCH": return "/dispatch-logistics";
            case "HARVESTING_MODULE":
            case "HARVESTING_MANAGEMENT":
            case "HARVESTING": return "/harvesting";
            case "DPR_MANAGEMENT":
            case "DPR":
            case "DAILY_PROGRESS_REPORT": return "/dpr";
            default: return "/user-dashboard";
        }
    }
}
