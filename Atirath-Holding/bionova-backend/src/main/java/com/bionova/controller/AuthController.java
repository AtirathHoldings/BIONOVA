package com.bionova.controller;

import com.bionova.dto.ForgotPasswordRequest;
import com.bionova.dto.LoginRequest;
import com.bionova.dto.LoginResponse;
import com.bionova.dto.ResetPasswordRequest;
import com.bionova.service.AuthService;
import com.bionova.service.PasswordResetService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    public AuthController(AuthService authService,
                          PasswordResetService passwordResetService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
    }

    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request) {
        return authService.login(request);
    }

    /**
     * Step 1 – POST /api/auth/forgot-password
     * Body: { "email": "user@example.com" }
     * Sends a reset link to the user's email.
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(
            @RequestBody ForgotPasswordRequest request) {

        String message = passwordResetService.sendResetLink(request.getEmail());
        return ResponseEntity.ok(Map.of("message", message));
    }

    /**
     * Step 2 – POST /api/auth/reset-password
     * Body: { "token": "uuid-token", "newPassword": "NewPass@123" }
     * Validates token and updates the password.
     */
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(
            @RequestBody ResetPasswordRequest request) {

        String result = passwordResetService.resetPassword(
                request.getToken(), request.getNewPassword());

        return switch (result) {
            case "SUCCESS" ->
                    ResponseEntity.ok(Map.of("message", "Password updated successfully."));
            case "TOKEN_EXPIRED" ->
                    ResponseEntity.badRequest().body(Map.of("error", "Reset link has expired. Please request a new one."));
            case "TOKEN_USED" ->
                    ResponseEntity.badRequest().body(Map.of("error", "This reset link has already been used."));
            default ->
                    ResponseEntity.badRequest().body(Map.of("error", "Invalid or expired reset link."));
        };
    }
}