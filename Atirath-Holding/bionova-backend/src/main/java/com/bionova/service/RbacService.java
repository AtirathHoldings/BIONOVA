package com.bionova.service;

import com.bionova.dto.ScreenPermissionDto;
import com.bionova.dto.SaveAccessRequest;
import com.bionova.dto.RoleDto;
import com.bionova.entity.*;
import com.bionova.repository.*;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
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


    public List<ScreenMaster> getAllScreens() {
        return screenMasterRepository.findAll();
    }

    public List<RoleDto> getAllRoles() {
        // Filter out employee-specific custom roles from templates dropdown lists
        return rbacRepository.findDistinctRoles().stream()
                .filter(r -> r.getRoleNm() != null && !r.getRoleNm().startsWith("Custom_"))
                .collect(Collectors.toList());
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
            savePermissionsForRole(finalRoleId, finalRoleNm, request.getPermissions());
        } 
        else if (hasOverrides(request.getRoleId(), request.getPermissions())) {
            // Save as an ad-hoc custom override role specific to this configuration
            finalRoleNm = "Custom_Access_" + System.currentTimeMillis();
            finalRoleId = rbacRepository.findMaxRoleId() + 1;
            savePermissionsForRole(finalRoleId, finalRoleNm, request.getPermissions());
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

    private void savePermissionsForRole(Integer roleId, String roleNm, List<ScreenPermissionDto> permissions) {
        if (permissions == null) return;
        List<RoleBasedAccessControl> rbacs = permissions.stream().map(p -> {
            RoleBasedAccessControl r = new RoleBasedAccessControl();
            r.setRoleId(roleId);
            r.setRoleNm(roleNm);
            r.setScreenId(p.getScreenId());
            r.setViewFlg(p.getViewFlg() != null && p.getViewFlg());
            r.setEditFlg(p.getEditFlg() != null && p.getEditFlg());
            r.setAddFlg(p.getAddFlg() != null && p.getAddFlg());
            r.setDeleteFlg(p.getDeleteFlg() != null && p.getDeleteFlg());
            return r;
        }).collect(Collectors.toList());
        rbacRepository.saveAll(rbacs);
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
}
