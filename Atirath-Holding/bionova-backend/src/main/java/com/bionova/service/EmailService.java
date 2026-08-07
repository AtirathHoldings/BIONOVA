package com.bionova.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    @org.springframework.beans.factory.annotation.Value("${spring.mail.username:admin@bionova.com}")
    private String fromEmail;

    public void sendWelcomeEmail(String toEmail, String rawPassword, String websiteUrl) {
        if (toEmail == null || toEmail.trim().isEmpty()) {
            return;
        }

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(toEmail);
            helper.setFrom(fromEmail);
            helper.setSubject("Welcome to Bionova! Your Account Details");

            String htmlContent = "<div style='font-family: Arial, sans-serif; padding: 20px; color: #333;'>"
                    + "<h2 style='color: #2563eb;'>Welcome to Bionova!</h2>"
                    + "<p>Dear Employee,</p>"
                    + "<p>Your account has been successfully created. You can now access the portal using the following credentials:</p>"
                    + "<div style='background: #f1f5f9; padding: 15px; border-radius: 8px; margin: 20px 0;'>"
                    + "  <p style='margin: 5px 0;'><strong>Website URL:</strong> <a href='" + websiteUrl + "'>" + websiteUrl + "</a></p>"
                    + "  <p style='margin: 5px 0;'><strong>User ID (Email):</strong> " + toEmail + "</p>"
                    + "  <p style='margin: 5px 0;'><strong>Password:</strong> " + rawPassword + "</p>"
                    + "</div>"
                    + "<p style='color: #e11d48; font-size: 13px;'>* Please change your password after your first login for security purposes.</p>"
                    + "<p>Best Regards,<br/>Bionova Admin Team</p>"
                    + "</div>";

            helper.setText(htmlContent, true);

            mailSender.send(message);
            System.out.println("Welcome email sent successfully to: " + toEmail);

        } catch (Exception e) {
            System.err.println("Failed to send welcome email to: " + toEmail);
            e.printStackTrace();
        }
    }
}
