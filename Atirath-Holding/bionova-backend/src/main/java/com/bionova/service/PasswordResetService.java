package com.bionova.service;

import com.bionova.entity.Employee;
import com.bionova.entity.PasswordResetToken;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.PasswordResetTokenRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class PasswordResetService {

    private final EmployeeRepository employeeRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final JavaMailSender mailSender;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.base-url:http://localhost:5173}")
    private String baseUrl;

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
     * Step 1 — User enters email → generate token → send reset link
     */
    @Transactional
    public String sendResetLink(String email) {
        Employee employee = employeeRepository.findByEmail(email).orElse(null);

        // Always return success message to avoid email enumeration attacks
        if (employee == null) {
            return "If this email is registered, a reset link has been sent.";
        }

        // Delete any existing tokens for this email (one at a time)
        tokenRepository.deleteByEmail(email);

        // Generate a secure random token
        String token = UUID.randomUUID().toString();

        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.setToken(token);
        resetToken.setEmail(email);
        resetToken.setExpiresAt(LocalDateTime.now().plusMinutes(30));
        resetToken.setUsed(false);
        tokenRepository.save(resetToken);

        // Build the reset link pointing to the frontend reset page
        String resetLink = baseUrl + "/reset-password?token=" + token;

        // Send the email
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(email);
        message.setSubject("BIONOVA – Password Reset Request");
        message.setText(
                "Hello " + employee.getFirstName() + ",\n\n" +
                "You requested to reset your BIONOVA account password.\n\n" +
                "Click the link below to set a new password (valid for 30 minutes):\n" +
                resetLink + "\n\n" +
                "If you did NOT request this, please ignore this email.\n\n" +
                "– BIONOVA Team"
        );
        mailSender.send(message);

        return "If this email is registered, a reset link has been sent.";
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

        employee.setPassword(passwordEncoder.encode(newPassword));
        employeeRepository.save(employee);

        // Mark token as used
        resetToken.setUsed(true);
        tokenRepository.save(resetToken);

        return "SUCCESS";
    }
}
