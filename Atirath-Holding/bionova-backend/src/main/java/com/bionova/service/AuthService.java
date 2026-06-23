package com.bionova.service;

import com.bionova.dto.LoginRequest;
import com.bionova.dto.LoginResponse;
import com.bionova.entity.Employee;
import com.bionova.repository.EmployeeRepository;
import com.bionova.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final EmployeeRepository employeeRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(EmployeeRepository employeeRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil) {
        this.employeeRepository = employeeRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    public LoginResponse login(LoginRequest request) {

        Employee employee =
                employeeRepository.findByEmail(request.getEmail())
                        .orElse(null);

        if (employee == null) {
            return new LoginResponse(false, "User Not Found", null, null);
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
            return new LoginResponse(false, "Invalid Password", null, null);
        }

        // Generate JWT
        String token = jwtUtil.generateToken(employee.getEmail(), employee.getRole());

        return new LoginResponse(true, "Login Success", employee.getRole(), token);
    }
}