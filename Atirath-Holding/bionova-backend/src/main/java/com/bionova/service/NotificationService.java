package com.bionova.service;

import com.bionova.entity.ActivityLog;
import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.entity.AppNotification;
import com.bionova.repository.ActivityLogRepository;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.AppNotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import jakarta.transaction.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class NotificationService {

    @Autowired
    private ActivityLogRepository activityLogRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private AppNotificationRepository appNotificationRepository;

    @Autowired
    private JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Scheduled(fixedDelay = 10000) // Runs every 10 seconds for real-time status transitions
    @Transactional
    public void processUnprocessedLogs() {
        List<ActivityLog> unprocessedLogs = activityLogRepository.findByProcessedFalse();
        if (unprocessedLogs.isEmpty()) {
            return;
        }

        System.out.println("Processing " + unprocessedLogs.size() + " status change logs for notifications...");

        for (ActivityLog log : unprocessedLogs) {
            try {
                boolean sent = false;
                if ("TASK".equalsIgnoreCase(log.getEntityTyp())) {
                    sent = sendTaskNotification(log);
                } else if ("MILESTONE".equalsIgnoreCase(log.getEntityTyp())) {
                    sent = sendMilestoneNotification(log);
                } else if ("PROJECT".equalsIgnoreCase(log.getEntityTyp())) {
                    sent = sendProjectNotification(log);
                }

                // Mark as processed
                log.setProcessed(true);
                activityLogRepository.save(log);
            } catch (Exception e) {
                System.err.println("Error processing notification for Log ID " + log.getLogId() + ": " + e.getMessage());
            }
        }
    }

    private boolean sendTaskNotification(ActivityLog log) {
        TaskLive task = taskLiveRepository.findById(log.getEntityId()).orElse(null);
        if (task == null) {
            System.out.println("Task with ID " + log.getEntityId() + " not found. Skipping notification.");
            return false;
        }

        Employee employee = (task.getEmpId() != null) ? employeeRepository.findById(task.getEmpId()).orElse(null) : null;
        String recipientEmail = (employee != null) ? employee.getEmail() : "siva@atirath.com";
        String recipientName = (employee != null) ? employee.getFirstName() + " " + employee.getLastName() : "Admin";

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(recipientEmail);
        message.setSubject("BIONOVA – Task Status Update: " + task.getTaskCd());

        StringBuilder body = new StringBuilder();
        body.append("Hello ").append(recipientName).append(",\n\n");
        body.append("There has been a status update for the task assigned to you:\n\n");
        body.append("Task Code: ").append(task.getTaskCd()).append("\n");
        body.append("Task Name: ").append(task.getTaskNm()).append("\n");
        body.append("Status Changed: ").append(log.getStatusFrom()).append(" ➜ ").append(log.getStatusTo()).append("\n");
        body.append("Deadline (End Date): ").append(task.getEndDt()).append("\n\n");

        LocalDate today = LocalDate.now();
        boolean isDelayed = false;
        if ("COMPLETED".equalsIgnoreCase(log.getStatusTo())) {
            if (task.getEndDt() != null) {
                if (today.isAfter(task.getEndDt())) {
                    isDelayed = true;
                    body.append("⚠️ Note: This task was completed with a DELAY. The deadline was ").append(task.getEndDt()).append(".\n\n");
                } else {
                    body.append("🎉 Congratulations! This task was completed ON TIME / AHEAD OF SCHEDULE (Lead Time).\n\n");
                }
            }
        } else {
            if (task.getEndDt() != null && today.isAfter(task.getEndDt())) {
                isDelayed = true;
                body.append("⚠️ Warning: This task has EXCEEDED its deadline of ").append(task.getEndDt()).append(". Current status is: ").append(log.getStatusTo()).append(". Please update or complete it as soon as possible.\n\n");
            }
        }

        body.append("Thank you,\nBIONOVA Team");

        message.setText(body.toString());
        mailSender.send(message);
        System.out.println("Sent task status update notification to: " + recipientEmail);

        // Save App Notification for Supabase Realtime Broadcast
        AppNotification appNotification = new AppNotification();
        appNotification.setEmpId(employee != null ? employee.getEmpId() : null);
        appNotification.setTitle("Task Update: " + task.getTaskCd());
        appNotification.setMessage("Task '" + task.getTaskNm() + "' status changed from " + log.getStatusFrom() + " to " + log.getStatusTo()
                + (isDelayed ? " (⚠️ DELAYED)" : ""));
        appNotification.setEntityTyp("TASK");
        appNotification.setEntityId(task.getTaskId());
        appNotificationRepository.save(appNotification);

        return true;
    }

    private boolean sendMilestoneNotification(ActivityLog log) {
        MilestoneLive ms = milestoneLiveRepository.findById(log.getEntityId()).orElse(null);
        if (ms == null) {
            System.out.println("Milestone with ID " + log.getEntityId() + " not found. Skipping notification.");
            return false;
        }

        ProjectLive project = projectLiveRepository.findById(ms.getPrjId()).orElse(null);
        String prjName = (project != null) ? project.getPrjNm() : "Unknown Project";

        String recipientEmail = "siva@atirath.com";

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(recipientEmail);
        message.setSubject("BIONOVA – Milestone Status Update: Project " + prjName);

        StringBuilder body = new StringBuilder();
        body.append("Hello Manager,\n\n");
        body.append("A milestone has been updated in project '").append(prjName).append("':\n\n");
        body.append("Milestone Name: ").append(ms.getMlstnTtl()).append("\n");
        body.append("Status Changed: ").append(log.getStatusFrom()).append(" ➜ ").append(log.getStatusTo()).append("\n");
        body.append("Target End Date: ").append(ms.getEndDt()).append("\n\n");

        LocalDate today = LocalDate.now();
        boolean isDelayed = false;
        if ("COMPLETED".equalsIgnoreCase(log.getStatusTo()) || "CLOSED".equalsIgnoreCase(log.getStatusTo())) {
            if (ms.getEndDt() != null) {
                if (today.isAfter(ms.getEndDt())) {
                    isDelayed = true;
                    body.append("⚠️ Note: This milestone was completed with a DELAY. The deadline was ").append(ms.getEndDt()).append(".\n\n");
                } else {
                    body.append("🎉 Success: This milestone was completed ON TIME / AHEAD OF SCHEDULE.\n\n");
                }
            }
        }

        body.append("Thank you,\nBIONOVA Team");

        message.setText(body.toString());
        mailSender.send(message);
        System.out.println("Sent milestone status update notification to: " + recipientEmail);

        // Save App Notification
        Employee manager = employeeRepository.findByEmail("siva@atirath.com").orElse(null);
        AppNotification appNotification = new AppNotification();
        appNotification.setEmpId(manager != null ? manager.getEmpId() : null);
        appNotification.setTitle("Milestone Update: " + ms.getMlstnCd());
        appNotification.setMessage("Milestone '" + ms.getMlstnTtl() + "' status changed from " + log.getStatusFrom() + " to " + log.getStatusTo()
                + (isDelayed ? " (⚠️ DELAYED)" : ""));
        appNotification.setEntityTyp("MILESTONE");
        appNotification.setEntityId(ms.getMId());
        appNotificationRepository.save(appNotification);

        return true;
    }

    private boolean sendProjectNotification(ActivityLog log) {
        ProjectLive project = projectLiveRepository.findById(log.getEntityId()).orElse(null);
        if (project == null) {
            System.out.println("Project with ID " + log.getEntityId() + " not found. Skipping notification.");
            return false;
        }

        String recipientEmail = "siva@atirath.com";

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail);
        message.setTo(recipientEmail);
        message.setSubject("BIONOVA – Project Status Update: " + project.getPrjNm());

        StringBuilder body = new StringBuilder();
        body.append("Hello Manager,\n\n");
        body.append("The status of the project has changed:\n\n");
        body.append("Project Code: ").append(project.getPrjCd()).append("\n");
        body.append("Project Name: ").append(project.getPrjNm()).append("\n");
        body.append("Status Changed: ").append(log.getStatusFrom()).append(" ➜ ").append(log.getStatusTo()).append("\n");
        body.append("Target End Date: ").append(project.getEndDt()).append("\n\n");

        LocalDate today = LocalDate.now();
        boolean isDelayed = false;
        if ("CLOSED".equalsIgnoreCase(log.getStatusTo())) {
            if (project.getEndDt() != null) {
                if (today.isAfter(project.getEndDt())) {
                    isDelayed = true;
                    body.append("⚠️ Note: The project was closed with a DELAY. Target end date was ").append(project.getEndDt()).append(".\n\n");
                } else {
                    body.append("🎉 Success: The project has been successfully completed and closed ON TIME.\n\n");
                }
            }
        }

        body.append("Thank you,\nBIONOVA Team");

        message.setText(body.toString());
        mailSender.send(message);
        System.out.println("Sent project status update notification to: " + recipientEmail);

        // Save App Notification
        Employee manager = employeeRepository.findByEmail("siva@atirath.com").orElse(null);
        AppNotification appNotification = new AppNotification();
        appNotification.setEmpId(manager != null ? manager.getEmpId() : null);
        appNotification.setTitle("Project Update: " + project.getPrjNm());
        appNotification.setMessage("Project status changed from " + log.getStatusFrom() + " to " + log.getStatusTo()
                + (isDelayed ? " (⚠️ DELAYED)" : ""));
        appNotification.setEntityTyp("PROJECT");
        appNotification.setEntityId(project.getPrjId());
        appNotificationRepository.save(appNotification);

        return true;
    }

    /**
     * Scheduled job to run every 5 minutes to verify and process reminders.
     */
    @Scheduled(fixedDelay = 300000) // Runs every 5 minutes
    @Transactional
    public void processReminders() {
        System.out.println("Processing reminders check for projects, milestones, and tasks...");

        // 1. Process Tasks
        List<TaskLive> activeTasks = taskLiveRepository.findAll().stream()
                .filter(t -> !"COMPLETED".equalsIgnoreCase(t.getTaskSts()))
                .filter(t -> !"CLOSED".equalsIgnoreCase(t.getTaskSts()))
                .collect(Collectors.toList());

        for (TaskLive task : activeTasks) {
            try {
                if (shouldSendReminder("TASK", task.getTaskId(), task.getStDt(), task.getEndDt())) {
                    sendReminderNotification("TASK", task.getTaskId(), task.getTaskCd(), task.getTaskNm(), task.getEmpId(), task.getEndDt());
                }
            } catch (Exception e) {
                System.err.println("Error checking task reminder for ID " + task.getTaskId() + ": " + e.getMessage());
            }
        }

        // 2. Process Milestones
        List<MilestoneLive> activeMilestones = milestoneLiveRepository.findAll().stream()
                .filter(m -> !"COMPLETED".equalsIgnoreCase(m.getMlstnSts()))
                .filter(m -> !"CLOSED".equalsIgnoreCase(m.getMlstnSts()))
                .collect(Collectors.toList());

        Employee manager = employeeRepository.findByEmail("siva@atirath.com").orElse(null);
        Long managerId = (manager != null) ? manager.getEmpId() : null;

        for (MilestoneLive ms : activeMilestones) {
            try {
                if (shouldSendReminder("MILESTONE", ms.getMId(), ms.getStDt(), ms.getEndDt())) {
                    sendReminderNotification("MILESTONE", ms.getMId(), ms.getMlstnCd(), ms.getMlstnTtl(), managerId, ms.getEndDt());
                }
            } catch (Exception e) {
                System.err.println("Error checking milestone reminder for ID " + ms.getMId() + ": " + e.getMessage());
            }
        }

        // 3. Process Projects
        List<ProjectLive> activeProjects = projectLiveRepository.findAll().stream()
                .filter(p -> !"CLOSED".equalsIgnoreCase(p.getPrjSts()))
                .collect(Collectors.toList());

        for (ProjectLive project : activeProjects) {
            try {
                if (shouldSendReminder("PROJECT", project.getPrjId(), project.getStDt(), project.getEndDt())) {
                    sendReminderNotification("PROJECT", project.getPrjId(), project.getPrjCd(), project.getPrjNm(), managerId, project.getEndDt());
                }
            } catch (Exception e) {
                System.err.println("Error checking project reminder for ID " + project.getPrjId() + ": " + e.getMessage());
            }
        }
    }

    private boolean shouldSendReminder(String entityTyp, Long entityId, LocalDate stDt, LocalDate endDt) {
        if (stDt == null || endDt == null) {
            return false;
        }

        LocalDate today = LocalDate.now();
        LocalDateTime now = LocalDateTime.now();

        // If current date is before start date, do not send reminders yet
        if (today.isBefore(stDt)) {
            return false;
        }

        // Find the latest reminder sent for this specific entity
        Optional<AppNotification> lastOpt = appNotificationRepository
                .findFirstByEntityTypAndEntityIdAndTitleContainingOrderByCreatedAtDesc(entityTyp, entityId, "Reminder");

        if (!lastOpt.isPresent()) {
            // First time sending reminder
            return true;
        }

        LocalDateTime lastSentTime = lastOpt.get().getCreatedAt();

        if (today.isAfter(endDt)) {
            // Rule 1: Overdue -> Every 1 hour
            return lastSentTime.isBefore(now.minusHours(1));
        } else if (today.isEqual(endDt)) {
            // Rule 2: On Due Date -> Every 3 hours
            return lastSentTime.isBefore(now.minusHours(3));
        } else {
            // Rule 3: Normal progress window -> Every 2 days (48 hours)
            return lastSentTime.isBefore(now.minusDays(2));
        }
    }

    private void sendReminderNotification(String entityTyp, Long entityId, String code, String name, Long empId, LocalDate endDt) {
        LocalDate today = LocalDate.now();
        String titlePrefix = "";
        String messageBody = "";

        if (today.isAfter(endDt)) {
            titlePrefix = "🚨 Overdue Reminder: ";
            messageBody = "The " + entityTyp.toLowerCase() + " '" + name + "' (" + code + ") is OVERDUE! Its deadline was " + endDt + ". Please update immediately.";
        } else if (today.isEqual(endDt)) {
            titlePrefix = "⚠️ Due Date Reminder: ";
            messageBody = "The " + entityTyp.toLowerCase() + " '" + name + "' (" + code + ") is due today. Please complete or update it.";
        } else {
            titlePrefix = "⏳ Regular Reminder: ";
            messageBody = "Regular check: The " + entityTyp.toLowerCase() + " '" + name + "' (" + code + ") is currently active and is due on " + endDt + ".";
        }

        String title = titlePrefix + code;

        // 1. Save App Notification for Supabase Realtime Broadcast
        AppNotification appNotification = new AppNotification();
        appNotification.setEmpId(empId);
        appNotification.setTitle(title);
        appNotification.setMessage(messageBody);
        appNotification.setEntityTyp(entityTyp);
        appNotification.setEntityId(entityId);
        appNotificationRepository.save(appNotification);
        System.out.println("Saved AppNotification reminder for " + entityTyp + " ID: " + entityId);

        // 2. Send Email Reminder
        String recipientEmail = "siva@atirath.com";
        if (empId != null) {
            Employee employee = employeeRepository.findById(empId).orElse(null);
            if (employee != null && employee.getEmail() != null) {
                recipientEmail = employee.getEmail();
            }
        }

        try {
            SimpleMailMessage mailMessage = new SimpleMailMessage();
            mailMessage.setFrom(fromEmail);
            mailMessage.setTo(recipientEmail);
            mailMessage.setSubject(title);
            mailMessage.setText("Hello,\n\n" + messageBody + "\n\nThank you,\nBIONOVA Team");
            mailSender.send(mailMessage);
            System.out.println("Sent email reminder to: " + recipientEmail + " for " + entityTyp + ": " + code);
        } catch (Exception e) {
            System.err.println("Failed to send email reminder to " + recipientEmail + ": " + e.getMessage());
        }
    }
}
