package com.bionova.service;

import com.bionova.entity.Employee;
import com.bionova.entity.PasswordResetToken;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.PasswordResetTokenRepository;
import jakarta.mail.internet.MimeMessage;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;
import java.util.logging.Logger;
import java.util.logging.Level;

@Service
public class PasswordResetService {

    private static final Logger log = Logger.getLogger(PasswordResetService.class.getName());

    private final EmployeeRepository employeeRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final JavaMailSender mailSender;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.base-url:http://localhost:5173}")
    private String baseUrl;

    @Value("${app.server-base-url:http://localhost:8080}")
    private String serverBaseUrl;

    @Value("${app.mobile-base-url:bionova://reset-password}")
    private String mobileBaseUrl;

    @Value("${app.mobile-app-link-url:https://bionova-rjii.onrender.com/reset-password}")
    private String mobileAppLinkUrl;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public PasswordResetService(EmployeeRepository employeeRepository,
                                PasswordResetTokenRepository tokenRepository,
                                JavaMailSender mailSender,
                                PasswordEncoder passwordEncoder) {
        this.employeeRepository = employeeRepository;
        this.tokenRepository = tokenRepository;
        this.mailSender = mailSender;
        this.passwordEncoder = passwordEncoder;
    }

    /**
     * Legacy method for backward compatibility
     */
    @Transactional
    public String sendResetLink(String email) {
        return sendResetLink(email, null, null, null, null, null, null);
    }

    /**
     * Step 1 — User enters email → generate token → send reset link (App vs Web)
     */
    @Transactional
    public String sendResetLink(String email, String source, String client, String platform,
                                String redirectUrl, String userAgent, String clientTypeHeader) {
        Employee employee = employeeRepository.findByEmail(email).orElse(null);

        // Always return success message to avoid email enumeration attacks
        if (employee == null) {
            return "If this email is registered, a reset link has been sent.";
        }

        // Delete any existing tokens for this email
        tokenRepository.deleteByEmail(email);

        // Generate a secure random token
        String token = UUID.randomUUID().toString();

        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.setToken(token);
        resetToken.setEmail(email);
        resetToken.setExpiresAt(LocalDateTime.now().plusMinutes(30));
        resetToken.setUsed(false);
        tokenRepository.save(resetToken);

        boolean isApp = isAppRequest(source, client, platform, userAgent, clientTypeHeader);
        String resetLink = buildResetLink(token, isApp, redirectUrl);

        log.info("Generating password reset link for email=" + email + " (isApp=" + isApp + "): " + resetLink);

        // Send Email (HTML with fallback)
        sendEmail(email, employee.getFirstName(), resetLink, isApp, token);

        return "If this email is registered, a reset link has been sent.";
    }

    public boolean isAppRequest(String source, String client, String platform, String userAgent, String clientTypeHeader) {
        if ("app".equalsIgnoreCase(source) || "mobile".equalsIgnoreCase(source) ||
            "app".equalsIgnoreCase(client) || "mobile".equalsIgnoreCase(client)) {
            return true;
        }
        if ("android".equalsIgnoreCase(platform) || "ios".equalsIgnoreCase(platform) ||
            "mobile".equalsIgnoreCase(platform) || "app".equalsIgnoreCase(platform)) {
            return true;
        }
        if ("app".equalsIgnoreCase(clientTypeHeader) || "mobile".equalsIgnoreCase(clientTypeHeader)) {
            return true;
        }
        if (userAgent != null) {
            String uaLower = userAgent.toLowerCase();
            if (uaLower.contains("dart") || uaLower.contains("flutter") || uaLower.contains("cbg_app") ||
                uaLower.contains("okhttp")) {
                return true;
            }
        }
        return false;
    }

    private String formatWebResetUrl(String base, String token) {
        String trimmed = (base != null && !base.trim().isEmpty()) ? base.trim() : "http://localhost:5173";
        if (!trimmed.contains("/reset-password")) {
            if (trimmed.endsWith("/")) {
                trimmed = trimmed.substring(0, trimmed.length() - 1);
            }
            trimmed = trimmed + "/reset-password";
        }
        String separator = trimmed.contains("?") ? "&" : "?";
        return trimmed + separator + "token=" + token;
    }

    private String buildResetLink(String token, boolean isApp, String customRedirectUrl) {
        if (customRedirectUrl != null && !customRedirectUrl.trim().isEmpty()) {
            String separator = customRedirectUrl.contains("?") ? "&" : "?";
            return customRedirectUrl.trim() + separator + "token=" + token;
        }
        if (isApp) {
            // For app requests, use HTTP/HTTPS smart bridge link so Gmail/Outlook email clients render it as a clickable button
            String targetBridge = serverBaseUrl.trim() + "/api/auth/open-reset";
            String separator = targetBridge.contains("?") ? "&" : "?";
            return targetBridge + separator + "token=" + token;
        } else {
            // For web requests, use web base URL pointing to /reset-password (e.g. http://localhost:5173/reset-password?token=...)
            return formatWebResetUrl(baseUrl, token);
        }
    }

    private void sendEmail(String toEmail, String firstName, String resetLink, boolean isApp, String token) {
        String name = (firstName != null && !firstName.isEmpty()) ? firstName : "User";
        String subject = "BIONOVA – Password Reset Request";
        String webResetLink = formatWebResetUrl(baseUrl, token);

        String htmlContent = "<!DOCTYPE html>" +
                "<html><head><meta charset='utf-8'/></head>" +
                "<body style='font-family: Arial, sans-serif; background-color: #f4f6f9; padding: 20px;'>" +
                "<div style='max-width: 500px; margin: 0 auto; background: #ffffff; padding: 30px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);'>" +
                "<h2 style='color: #2563EB; margin-top: 0;'>BIONOVA</h2>" +
                "<p>Hello <strong>" + name + "</strong>,</p>" +
                "<p>You requested to reset your BIONOVA account password. Click below to reset your password (valid for 30 minutes):</p>" +
                "<p style='margin: 25px 0; text-align: center;'>" +
                "<a href='" + resetLink + "' style='background-color: #2563EB; color: #ffffff; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; display: inline-block;'>Reset Password " + (isApp ? "in App" : "on Website") + "</a>" +
                "</p>" +
                (isApp ? "<p style='font-size: 13px; color: #666; text-align: center;'>Opening email on a Laptop or Web Browser?<br/><a href='" + webResetLink + "' style='color: #2563EB; font-weight: bold;'>Click here to reset on Website</a></p>" : "") +
                "<p style='font-size: 13px; color: #666;'>If the button above does not open directly, copy and paste this link into your application or browser:</p>" +
                "<p style='font-size: 13px; word-break: break-all; color: #2563EB;'><a href='" + resetLink + "'>" + resetLink + "</a></p>" +
                "<hr style='border: none; border-top: 1px solid #eee; margin: 20px 0;'/>" +
                "<p style='font-size: 12px; color: #888;'>If you did NOT request this, please ignore this email.</p>" +
                "</div></body></html>";

        String textContent = "Hello " + name + ",\n\n" +
                "You requested to reset your BIONOVA account password.\n\n" +
                "Click the link below to set a new password (valid for 30 minutes):\n" +
                resetLink + "\n\n" +
                (isApp ? "Opening on laptop/desktop? Use web link:\n" + webResetLink + "\n\n" : "") +
                "If you did NOT request this, please ignore this email.\n\n" +
                "– BIONOVA Team";

        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");
            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject(subject);
            helper.setText(textContent, htmlContent);
            mailSender.send(mimeMessage);
        } catch (Exception e) {
            log.log(Level.WARNING, "Failed to send MimeMessage HTML email for reset link, falling back to SimpleMailMessage: " + e.getMessage());
            try {
                SimpleMailMessage message = new SimpleMailMessage();
                message.setFrom(fromEmail);
                message.setTo(toEmail);
                message.setSubject(subject);
                message.setText(textContent);
                mailSender.send(message);
            } catch (Exception ex) {
                log.log(Level.SEVERE, "Failed to send SimpleMailMessage for password reset: " + ex.getMessage(), ex);
            }
        }
    }

    /**
     * Step 2 — User clicks link in email → submit new password
     */
    @Transactional
    public String resetPassword(String token, String newPassword) {
        PasswordResetToken resetToken = tokenRepository.findByToken(token).orElse(null);

        if (resetToken == null) {
            return "INVALID_TOKEN";
        }
        if (resetToken.isUsed()) {
            return "TOKEN_USED";
        }
        if (resetToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            return "TOKEN_EXPIRED";
        }

        // Update the employee password
        Employee employee = employeeRepository.findByEmail(resetToken.getEmail()).orElse(null);
        if (employee == null) {
            return "INVALID_TOKEN";
        }

        if (employee.getPassword() != null && passwordEncoder.matches(newPassword, employee.getPassword())) {
            return "SAME_AS_OLD_PASSWORD";
        }

        employee.setPassword(passwordEncoder.encode(newPassword));
        employeeRepository.save(employee);

        // Mark token as used
        resetToken.setUsed(true);
        tokenRepository.save(resetToken);

        return "SUCCESS";
    }
}

