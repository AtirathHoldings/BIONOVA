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

    @org.springframework.beans.factory.annotation.Autowired
    private com.bionova.repository.EmployeeRepository employeeRepository;

    @org.springframework.beans.factory.annotation.Autowired
    private com.bionova.repository.PlantRepository plantRepository;

    @org.springframework.beans.factory.annotation.Autowired
    private com.bionova.security.JwtUtil jwtUtil;

    @org.springframework.beans.factory.annotation.Value("${app.base-url:http://localhost:5173}")
    private String baseUrl;

    public AuthController(AuthService authService,
                          PasswordResetService passwordResetService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
    }

    @GetMapping("/temp-token")
    public ResponseEntity<?> getTempToken(
            @RequestParam(required = false) String email,
            @RequestParam(required = false) Long empId) {
        String finalEmail = (email != null && !email.trim().isEmpty()) ? email : "vsv.vempati@gmail.com";
        String token = jwtUtil.generateToken(finalEmail, "full_access", empId);
        return ResponseEntity.ok(Map.of("token", token));
    }

    @GetMapping("/debug-employees")
    public ResponseEntity<?> debugEmployees() {
        return ResponseEntity.ok(Map.of(
            "employees", employeeRepository.findAll(),
            "plants", plantRepository.findAll()
        ));
    }

    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request,
                               @RequestHeader(value = "User-Agent", required = false) String userAgent) {
        return authService.login(request, userAgent);
    }

    /**
     * Step 1 – POST /api/auth/forgot-password
     * Body: { "email": "user@example.com", "source": "app" }
     * Sends a reset link to the user's email targeting App or Web depending on client origin.
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(
            @RequestBody ForgotPasswordRequest request,
            @RequestHeader(value = "User-Agent", required = false) String userAgent,
            @RequestHeader(value = "X-Client-Type", required = false) String clientTypeHeader) {

        String message = passwordResetService.sendResetLink(
                request.getEmail(),
                request.getSource(),
                request.getClient(),
                request.getPlatform(),
                request.getRedirectUrl(),
                userAgent,
                clientTypeHeader
        );
        return ResponseEntity.ok(Map.of("message", message));
    }

    /**
     * Smart Deep Link Bridge Page – GET /api/auth/open-reset?token=XYZ
     * Opens the mobile app directly or offers fallback to web reset.
     */
    /**
     * Smart Deep Link Bridge Page – GET /api/auth/open-reset?token=XYZ
     * Opens the mobile app directly via Android Intent / Custom Scheme or offers web reset.
     */
    @GetMapping("/open-reset")
    public ResponseEntity<String> openResetInApp(
            @RequestParam("token") String token,
            @RequestParam(value = "target", required = false, defaultValue = "app") String target) {

        String schemeLink = "bionova://reset-password?token=" + token;
        String intentLink = "intent://reset-password?token=" + token + "#Intent;scheme=bionova;package=com.example.cbg_app;end";
        
        String cleanBase = (baseUrl != null && !baseUrl.trim().isEmpty()) ? baseUrl.trim() : "http://localhost:5173";
        if (!cleanBase.contains("/reset-password")) {
            if (cleanBase.endsWith("/")) {
                cleanBase = cleanBase.substring(0, cleanBase.length() - 1);
            }
            cleanBase = cleanBase + "/reset-password";
        }
        String webLink = cleanBase + (cleanBase.contains("?") ? "&" : "?") + "token=" + token;

        String html = "<!DOCTYPE html><html><head>" +
                "<meta charset='utf-8'/><meta name='viewport' content='width=device-width, initial-scale=1'/>" +
                "<title>BioNova Password Reset</title>" +
                "<script>" +
                "  function openApp() {" +
                "    var isAndroid = /Android/i.test(navigator.userAgent);" +
                "    if (isAndroid) {" +
                "      window.location.href = '" + intentLink + "';" +
                "    } else {" +
                "      window.location.href = '" + schemeLink + "';" +
                "    }" +
                "  }" +
                "  window.onload = function() {" +
                "    openApp();" +
                "  };" +
                "</script></head>" +
                "<body style='font-family: system-ui, -apple-system, sans-serif; text-align: center; padding: 40px 20px; background: #f8fafc; color: #1e293b;'>" +
                "<div style='max-width: 420px; margin: 0 auto; background: #fff; padding: 30px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);'>" +
                "<h2 style='color: #2563eb; margin-top: 0;'>BioNova Password Reset</h2>" +
                "<p style='color: #475569; font-size: 15px;'>Opening the BioNova App to reset your password...</p>" +
                "<div style='margin-top: 25px; display: flex; flex-direction: column; gap: 14px;'>" +
                "<a href='" + intentLink + "' onclick='openApp()' style='background: #2563eb; color: #fff; padding: 14px; text-decoration: none; border-radius: 8px; font-weight: 600; display: block;'>📱 Open BioNova App</a>" +
                "<a href='" + webLink + "' style='background: #f1f5f9; color: #334155; padding: 14px; text-decoration: none; border-radius: 8px; font-weight: 600; display: block;'>💻 Open on Website (Laptop)</a>" +
                "</div>" +
                "</div></body></html>";

        return ResponseEntity.ok().header("Content-Type", "text/html; charset=UTF-8").body(html);
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
                    ResponseEntity.badRequest().body(Map.of("error", "This reset link has already been used. Please request a new one."));
            case "SAME_AS_OLD_PASSWORD" ->
                    ResponseEntity.badRequest().body(Map.of("error", "New password cannot be the same as your previous password. Please enter a different password."));
            default ->
                    ResponseEntity.badRequest().body(Map.of("error", "Invalid or expired reset link. Please request a new one."));
        };
    }
}