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

    public void sendExternalTaskAssignmentEmail(String toEmail, String employeeName, String taskName,
                                               String projectName, String magicLinkUrl,
                                               java.time.LocalDateTime expiryDate) {
        if (toEmail == null || toEmail.trim().isEmpty()) {
            return;
        }

        String recipient = (employeeName != null && !employeeName.trim().isEmpty()) ? employeeName : "Associate";
        String taskTitle = (taskName != null && !taskName.trim().isEmpty()) ? taskName : "Assigned Task";
        String projTitle = (projectName != null && !projectName.trim().isEmpty()) ? projectName : "Project";
        String formattedExpiry = expiryDate != null
                ? expiryDate.format(java.time.format.DateTimeFormatter.ofPattern("dd-MMM-yyyy hh:mm a"))
                : "7 days from assignment";

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(toEmail);
            helper.setFrom(fromEmail);
            helper.setSubject("BIONOVA – Task Assignment: " + taskTitle);

            String htmlContent = "<div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden;'>"
                    + "<div style='background: #2563eb; padding: 20px; color: #ffffff;'>"
                    + "  <h2 style='margin: 0; font-size: 20px;'>BIONOVA Project Portal</h2>"
                    + "  <p style='margin: 5px 0 0 0; opacity: 0.9; font-size: 14px;'>New Task Assignment</p>"
                    + "</div>"
                    + "<div style='padding: 24px; color: #334155;'>"
                    + "  <p style='font-size: 15px; margin-top: 0;'>Hello <strong>" + recipient + "</strong>,</p>"
                    + "  <p style='font-size: 14px; line-height: 1.5;'>You have been assigned to a task for project <strong>" + projTitle + "</strong>. You can view the task specifications, mark checklist items, and submit your progress directly via your private task link below.</p>"
                    + "  <div style='background: #f8fafc; border: 1px solid #e2e8f0; padding: 16px; border-radius: 6px; margin: 20px 0;'>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Project:</strong> " + projTitle + "</p>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Task:</strong> " + taskTitle + "</p>"
                    + "    <p style='margin: 4px 0; font-size: 13px; color: #b91c1c;'><strong>Link Valid Until:</strong> " + formattedExpiry + "</p>"
                    + "  </div>"
                    + "  <div style='text-align: center; margin: 30px 0;'>"
                    + "    <a href='" + magicLinkUrl + "' style='background-color: #2563eb; color: #ffffff; padding: 12px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 14px;'>Open Task Workspace</a>"
                    + "  </div>"
                    + "  <p style='font-size: 12px; color: #64748b; margin-bottom: 5px;'>If the button above does not work, copy and paste the link below into your web browser:</p>"
                    + "  <p style='font-size: 12px; word-break: break-all; color: #2563eb;'><a href='" + magicLinkUrl + "'>" + magicLinkUrl + "</a></p>"
                    + "  <hr style='border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;'/>"
                    + "  <p style='font-size: 12px; color: #94a3b8; margin: 0;'>* This link is unique to you and provides direct access only to this assigned task.</p>"
                    + "</div>"
                    + "</div>";

            helper.setText(htmlContent, true);

            mailSender.send(message);
            System.out.println("External task assignment email sent successfully to: " + toEmail);

        } catch (Exception e) {
            System.err.println("Failed to send external task assignment email to: " + toEmail + " - Error: " + e.getMessage());
        }
    }

    public void sendExternalTaskExtensionEmail(String toEmail, String employeeName, String taskName,
                                              String projectName, String magicLinkUrl,
                                              java.time.LocalDateTime newExpiryDate,
                                              int additionalDays, String remarks) {
        if (toEmail == null || toEmail.trim().isEmpty()) {
            return;
        }

        String recipient = (employeeName != null && !employeeName.trim().isEmpty()) ? employeeName : "Associate";
        String taskTitle = (taskName != null && !taskName.trim().isEmpty()) ? taskName : "Assigned Task";
        String projTitle = (projectName != null && !projectName.trim().isEmpty()) ? projectName : "Project";
        String formattedExpiry = newExpiryDate != null
                ? newExpiryDate.format(java.time.format.DateTimeFormatter.ofPattern("dd-MMM-yyyy hh:mm a"))
                : "Updated Deadline";

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(toEmail);
            helper.setFrom(fromEmail);
            helper.setSubject("BIONOVA – Access Extended for Task: " + taskTitle);

            String htmlContent = "<div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden;'>"
                    + "<div style='background: #059669; padding: 20px; color: #ffffff;'>"
                    + "  <h2 style='margin: 0; font-size: 20px;'>BIONOVA Project Portal</h2>"
                    + "  <p style='margin: 5px 0 0 0; opacity: 0.9; font-size: 14px;'>Task Access Deadline Extended</p>"
                    + "</div>"
                    + "<div style='padding: 24px; color: #334155;'>"
                    + "  <p style='font-size: 15px; margin-top: 0;'>Hello <strong>" + recipient + "</strong>,</p>"
                    + "  <p style='font-size: 14px; line-height: 1.5;'>Your access to task <strong>" + taskTitle + "</strong> in project <strong>" + projTitle + "</strong> has been granted an extension of <strong>" + additionalDays + " additional day(s)</strong> by the Project Administrator.</p>"
                    + (remarks != null && !remarks.trim().isEmpty() ? "<p style='font-size: 13px; background: #f1f5f9; padding: 10px; border-radius: 6px; color: #475569;'><strong>Note from Admin:</strong> " + remarks + "</p>" : "")
                    + "  <div style='background: #ecfdf5; border: 1px solid #a7f3d0; padding: 16px; border-radius: 6px; margin: 20px 0;'>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Project:</strong> " + projTitle + "</p>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Task:</strong> " + taskTitle + "</p>"
                    + "    <p style='margin: 4px 0; font-size: 14px; color: #047857;'><strong>New Link Expiry:</strong> " + formattedExpiry + "</p>"
                    + "  </div>"
                    + "  <div style='text-align: center; margin: 30px 0;'>"
                    + "    <a href='" + magicLinkUrl + "' style='background-color: #059669; color: #ffffff; padding: 12px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 14px;'>Continue Task Workspace</a>"
                    + "  </div>"
                    + "  <p style='font-size: 12px; color: #64748b; margin-bottom: 5px;'>If the button above does not work, copy and paste the link below into your web browser:</p>"
                    + "  <p style='font-size: 12px; word-break: break-all; color: #059669;'><a href='" + magicLinkUrl + "'>" + magicLinkUrl + "</a></p>"
                    + "  <hr style='border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;'/>"
                    + "  <p style='font-size: 12px; color: #94a3b8; margin: 0;'>* This link is active until the new expiration deadline.</p>"
                    + "</div>"
                    + "</div>";

            helper.setText(htmlContent, true);

            mailSender.send(message);
            System.out.println("External task extension email sent successfully to: " + toEmail);

        } catch (Exception e) {
            System.err.println("Failed to send external task extension email to: " + toEmail + " - Error: " + e.getMessage());
        }
    }

    public void sendExternalTaskReworkEmail(String toEmail, String employeeName, String taskName,
                                           String projectName, String magicLinkUrl,
                                           String reviewerRole, String reviewerName, String remarks,
                                           java.time.LocalDateTime expiryDate) {
        if (toEmail == null || toEmail.trim().isEmpty()) {
            return;
        }

        String recipient = (employeeName != null && !employeeName.trim().isEmpty()) ? employeeName : "Associate";
        String taskTitle = (taskName != null && !taskName.trim().isEmpty()) ? taskName : "Assigned Task";
        String projTitle = (projectName != null && !projectName.trim().isEmpty()) ? projectName : "Project";
        String revRole = (reviewerRole != null && !reviewerRole.trim().isEmpty()) ? reviewerRole : "Reviewer";
        String revName = (reviewerName != null && !reviewerName.trim().isEmpty()) ? reviewerName : "Reviewer";
        String cleanRemarks = (remarks != null && !remarks.trim().isEmpty()) ? remarks.trim() : "No specific remarks provided.";
        String formattedExpiry = expiryDate != null
                ? expiryDate.format(java.time.format.DateTimeFormatter.ofPattern("dd-MMM-yyyy hh:mm a"))
                : "Active";

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(toEmail);
            helper.setFrom(fromEmail);
            helper.setSubject("BIONOVA – Action Required: Task Rework Needed for " + taskTitle);

            String htmlContent = "<div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden;'>"
                    + "<div style='background: #dc2626; padding: 20px; color: #ffffff;'>"
                    + "  <h2 style='margin: 0; font-size: 20px;'>BIONOVA Project Portal</h2>"
                    + "  <p style='margin: 5px 0 0 0; opacity: 0.95; font-size: 14px;'>Task Review: Rework Requested</p>"
                    + "</div>"
                    + "<div style='padding: 24px; color: #334155;'>"
                    + "  <p style='font-size: 15px; margin-top: 0;'>Hello <strong>" + recipient + "</strong>,</p>"
                    + "  <p style='font-size: 14px; line-height: 1.5;'>Your task submission for project <strong>" + projTitle + "</strong> has been reviewed by <strong>" + revName + " (" + revRole + ")</strong> and sent back for <strong>rework / updates</strong> before final approval.</p>"
                    + "  <div style='background: #fef2f2; border: 1px solid #fecaca; padding: 16px; border-radius: 6px; margin: 20px 0;'>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Project:</strong> " + projTitle + "</p>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Task:</strong> " + taskTitle + "</p>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Reviewed By:</strong> " + revName + " (" + revRole + ")</p>"
                    + "    <p style='margin: 8px 0 4px 0; font-size: 13px; color: #991b1b;'><strong>Reviewer Feedback / Remarks:</strong></p>"
                    + "    <div style='background: #ffffff; border: 1px solid #fee2e2; padding: 10px; border-radius: 4px; font-size: 13px; color: #7f1d1d; white-space: pre-wrap;'>" + cleanRemarks + "</div>"
                    + "    <p style='margin: 10px 0 0 0; font-size: 13px; color: #b91c1c;'><strong>Link Valid Until:</strong> " + formattedExpiry + "</p>"
                    + "  </div>"
                    + "  <p style='font-size: 14px; line-height: 1.5;'>Checklists for this task have been reopened. Please update the necessary deliverables and resubmit through your private task link below:</p>"
                    + "  <div style='text-align: center; margin: 28px 0;'>"
                    + "    <a href='" + magicLinkUrl + "' style='background-color: #dc2626; color: #ffffff; padding: 12px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 14px;'>Open Task Workspace to Rework</a>"
                    + "  </div>"
                    + "  <p style='font-size: 12px; color: #64748b; margin-bottom: 5px;'>If the button above does not work, copy and paste the link below into your web browser:</p>"
                    + "  <p style='font-size: 12px; word-break: break-all; color: #dc2626;'><a href='" + magicLinkUrl + "'>" + magicLinkUrl + "</a></p>"
                    + "  <hr style='border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;'/>"
                    + "  <p style='font-size: 12px; color: #94a3b8; margin: 0;'>* This link is unique to you and provides direct access only to this assigned task.</p>"
                    + "</div>"
                    + "</div>";

            helper.setText(htmlContent, true);

            mailSender.send(message);
            System.out.println("External task rework email sent successfully to: " + toEmail);

        } catch (Exception e) {
            System.err.println("Failed to send external task rework email to: " + toEmail + " - Error: " + e.getMessage());
        }
    }

    public void sendExternalTaskReassignEmail(String toEmail, String employeeName, String taskName,
                                            String projectName, String magicLinkUrl,
                                            String reassignerRole, String reassignerName, String remarks,
                                            java.time.LocalDateTime expiryDate) {
        if (toEmail == null || toEmail.trim().isEmpty()) {
            return;
        }

        String recipient = (employeeName != null && !employeeName.trim().isEmpty()) ? employeeName : "Associate";
        String taskTitle = (taskName != null && !taskName.trim().isEmpty()) ? taskName : "Assigned Task";
        String projTitle = (projectName != null && !projectName.trim().isEmpty()) ? projectName : "Project";
        String rRole = (reassignerRole != null && !reassignerRole.trim().isEmpty()) ? reassignerRole : "Reviewer";
        String rName = (reassignerName != null && !reassignerName.trim().isEmpty()) ? reassignerName : "Manager";
        String cleanRemarks = (remarks != null && !remarks.trim().isEmpty()) ? remarks.trim() : "";
        String formattedExpiry = expiryDate != null
                ? expiryDate.format(java.time.format.DateTimeFormatter.ofPattern("dd-MMM-yyyy hh:mm a"))
                : "7 days from assignment";

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(toEmail);
            helper.setFrom(fromEmail);
            helper.setSubject("BIONOVA – Task Reassigned: " + taskTitle);

            String htmlContent = "<div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden;'>"
                    + "<div style='background: #2563eb; padding: 20px; color: #ffffff;'>"
                    + "  <h2 style='margin: 0; font-size: 20px;'>BIONOVA Project Portal</h2>"
                    + "  <p style='margin: 5px 0 0 0; opacity: 0.9; font-size: 14px;'>Task Reassigned</p>"
                    + "</div>"
                    + "<div style='padding: 24px; color: #334155;'>"
                    + "  <p style='font-size: 15px; margin-top: 0;'>Hello <strong>" + recipient + "</strong>,</p>"
                    + "  <p style='font-size: 14px; line-height: 1.5;'>You have been assigned to task <strong>" + taskTitle + "</strong> in project <strong>" + projTitle + "</strong> following a reassignment by <strong>" + rName + " (" + rRole + ")</strong>.</p>"
                    + "  <div style='background: #f8fafc; border: 1px solid #e2e8f0; padding: 16px; border-radius: 6px; margin: 20px 0;'>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Project:</strong> " + projTitle + "</p>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Task:</strong> " + taskTitle + "</p>"
                    + "    <p style='margin: 4px 0; font-size: 14px;'><strong>Reassigned By:</strong> " + rName + " (" + rRole + ")</p>"
                    + (!cleanRemarks.isEmpty() ? ("    <p style='margin: 8px 0 4px 0; font-size: 13px; color: #475569;'><strong>Instructions / Remarks:</strong></p><div style='background: #ffffff; border: 1px solid #e2e8f0; padding: 10px; border-radius: 4px; font-size: 13px; color: #334155; white-space: pre-wrap;'>" + cleanRemarks + "</div>") : "")
                    + "    <p style='margin: 10px 0 0 0; font-size: 13px; color: #b91c1c;'><strong>Link Valid Until:</strong> " + formattedExpiry + "</p>"
                    + "  </div>"
                    + "  <div style='text-align: center; margin: 28px 0;'>"
                    + "    <a href='" + magicLinkUrl + "' style='background-color: #2563eb; color: #ffffff; padding: 12px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; font-size: 14px;'>Open Task Workspace</a>"
                    + "  </div>"
                    + "  <p style='font-size: 12px; color: #64748b; margin-bottom: 5px;'>If the button above does not work, copy and paste the link below into your web browser:</p>"
                    + "  <p style='font-size: 12px; word-break: break-all; color: #2563eb;'><a href='" + magicLinkUrl + "'>" + magicLinkUrl + "</a></p>"
                    + "  <hr style='border: none; border-top: 1px solid #e2e8f0; margin: 20px 0;'/>"
                    + "  <p style='font-size: 12px; color: #94a3b8; margin: 0;'>* This link is unique to you and provides direct access only to this assigned task.</p>"
                    + "</div>"
                    + "</div>";

            helper.setText(htmlContent, true);

            mailSender.send(message);
            System.out.println("External task reassign email sent successfully to: " + toEmail);

        } catch (Exception e) {
            System.err.println("Failed to send external task reassign email to: " + toEmail + " - Error: " + e.getMessage());
        }
    }
}
