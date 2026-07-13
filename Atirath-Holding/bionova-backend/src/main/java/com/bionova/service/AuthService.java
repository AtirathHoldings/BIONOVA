package com.bionova.service;

import com.bionova.dto.LoginRequest;
import com.bionova.dto.LoginResponse;
import com.bionova.entity.Employee;
import com.bionova.entity.RoleBasedEmployeeMapping;
import com.bionova.entity.RoleBasedAccessControl;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.RoleBasedEmployeeMappingRepository;
import com.bionova.repository.RoleBasedAccessControlRepository;
import com.bionova.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AuthService {

    private final EmployeeRepository employeeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final RoleBasedEmployeeMappingRepository employeeMappingRepository;
    private final RoleBasedAccessControlRepository rbacRepository;
    private final EmployeeSettingsService employeeSettingsService;

    public AuthService(EmployeeRepository employeeRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil,
                       RoleBasedEmployeeMappingRepository employeeMappingRepository,
                       RoleBasedAccessControlRepository rbacRepository,
                       EmployeeSettingsService employeeSettingsService) {
        this.employeeRepository = employeeRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.employeeMappingRepository = employeeMappingRepository;
        this.rbacRepository = rbacRepository;
        this.employeeSettingsService = employeeSettingsService;
    }

    public LoginResponse login(LoginRequest request, String userAgent) {

        Employee employee =
                employeeRepository.findByEmail(request.getEmail())
                        .orElse(null);

        if (employee == null) {
            return new LoginResponse(false, "User Not Found", null, null, null);
        }

        String rawPassword    = request.getPassword();
        String storedPassword = employee.getPassword();

        boolean matches;
        if (storedPassword != null && storedPassword.startsWith("$2a$")) {
            matches = passwordEncoder.matches(rawPassword, storedPassword);
        } else {
            matches = rawPassword != null && rawPassword.equals(storedPassword);
        }

        if (!matches) {
            return new LoginResponse(false, "Invalid Password", null, null, null);
        }

        // Determine role:
        // - If employee has an RBAC mapping → use the mapped role name
        // - If no mapping exists → "full_access" (all screens visible, filter after RBAC setup)
        String role = "full_access";
        List<RoleBasedEmployeeMapping> mappings = employeeMappingRepository.findByEmpId(employee.getEmpId());
        if (!mappings.isEmpty()) {
            List<RoleBasedAccessControl> rbacList = rbacRepository.findByRoleId(mappings.get(0).getRoleId());
            if (!rbacList.isEmpty()) {
                role = rbacList.get(0).getRoleNm();
            }
        }

        // Generate JWT (embed empId so RBAC guard can identify the employee)
        String token = jwtUtil.generateToken(employee.getEmail(), role, employee.getEmpId());

        // Record Login Activity
        String determinedDevice = determineDeviceInfo(userAgent, request.getDeviceInfo());
        employeeSettingsService.recordLoginActivity(employee.getEmpId(), determinedDevice);

        return new LoginResponse(true, "Login Success", role, token, employee.getEmpId());
    }

    private String determineDeviceInfo(String userAgent, String requestDeviceInfo) {
        if (requestDeviceInfo != null && !requestDeviceInfo.trim().isEmpty()) {
            return requestDeviceInfo.trim();
        }
        if (userAgent == null || userAgent.isEmpty()) {
            return "Unknown Device";
        }
        
        String ua = userAgent.toLowerCase();
        
        // Check for Mobile App (Flutter / Dart / OkHttp / Swift)
        if (ua.contains("dart") || ua.contains("flutter") || ua.contains("okhttp") || ua.contains("retrofit") || ua.contains("android-app") || ua.contains("mobile-app")) {
            if (ua.contains("android")) {
                return "Android App";
            } else if (ua.contains("iphone") || ua.contains("ipad") || ua.contains("darwin") || ua.contains("cfnetwork")) {
                return "iOS App";
            }
            return "Mobile App";
        }
        
        // Determine OS
        String os = "Unknown OS";
        if (ua.contains("windows")) {
            os = "Windows";
        } else if (ua.contains("macintosh") || ua.contains("mac os")) {
            os = "Mac";
        } else if (ua.contains("linux")) {
            os = "Linux";
        } else if (ua.contains("android")) {
            os = "Android";
            if (ua.contains("chrome")) return "Chrome - Android";
            return "Mobile Browser - Android";
        } else if (ua.contains("iphone") || ua.contains("ipad")) {
            os = "iOS";
            if (ua.contains("safari")) return "Safari - iOS";
            return "Mobile Browser - iOS";
        }
        
        // Determine Browser
        String browser = "Browser";
        if (ua.contains("edg/")) {
            browser = "Edge";
        } else if (ua.contains("chrome") || ua.contains("crios")) {
            browser = "Chrome";
        } else if (ua.contains("firefox") || ua.contains("fxios")) {
            browser = "Firefox";
        } else if (ua.contains("safari") && !ua.contains("chrome")) {
            browser = "Safari";
        }
        
        return browser + " - " + os;
    }
}