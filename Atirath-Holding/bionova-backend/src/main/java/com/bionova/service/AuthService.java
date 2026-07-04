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

    public AuthService(EmployeeRepository employeeRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil,
                       RoleBasedEmployeeMappingRepository employeeMappingRepository,
                       RoleBasedAccessControlRepository rbacRepository) {
        this.employeeRepository = employeeRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.employeeMappingRepository = employeeMappingRepository;
        this.rbacRepository = rbacRepository;
    }

    public LoginResponse login(LoginRequest request) {

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

        // Generate JWT
        String token = jwtUtil.generateToken(employee.getEmail(), role);

        return new LoginResponse(true, "Login Success", role, token, employee.getEmpId());
    }
}