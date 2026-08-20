package com.bionova.service;

import com.bionova.dto.ExternalTaskUpdateDto;
import com.bionova.dto.ExternalTaskViewDto;
import com.bionova.entity.*;
import com.bionova.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ExternalTaskAccessService {

    @Autowired
    private ProjectTaskExternalTokenRepository tokenRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private ExternalEmployeeRepository externalEmployeeRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private ChecklistMasterRepository checklistMasterRepository;

    @Autowired
    private AttachmentMasterRepository attachmentMasterRepository;

    @Autowired
    private EmailService emailService;

    @Autowired
    private ProjectStatusCascadeService projectStatusCascadeService;

    @Autowired
    private ProcessConfigRepository processConfigRepository;

    @Autowired
    private ReviewerMasterRepository reviewerMasterRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Value("${app.base-url:http://localhost:5173}")
    private String baseUrl;

    /**
     * Generate or refresh the magic access token for an assigned external employee on a project task.
     * Expiry is strictly bounded by the Task Due Date (endDt at 23:59:59) or 7 days if not set.
     */
    @Transactional
    public ProjectTaskExternalToken generateOrRefreshToken(Long taskId, Long extEmpId) {
        if (taskId == null || extEmpId == null) {
            return null;
        }

        TaskLive task = taskLiveRepository.findById(taskId).orElse(null);
        ExternalEmployee extEmp = externalEmployeeRepository.findById(extEmpId).orElse(null);

        if (task == null || extEmp == null) {
            System.err.println("Cannot generate external token: Task or ExternalEmployee not found. TaskId=" + taskId + ", ExtEmpId=" + extEmpId);
            return null;
        }

        // Expiry Rule: Strictly by Task Due Date (endDt at 23:59:59). If endDt is not present or past, default to 7 days.
        LocalDateTime expiryDt;
        if (task.getEndDt() != null) {
            expiryDt = task.getEndDt().atTime(23, 59, 59);
        } else {
            expiryDt = LocalDateTime.now().plusDays(7).withHour(23).withMinute(59).withSecond(59);
        }

        String tokenStr = UUID.randomUUID().toString().replace("-", "") + UUID.randomUUID().toString().substring(0, 8);

        ProjectTaskExternalToken tokenEntity = tokenRepository.findByTaskIdAndExtEmpId(taskId, extEmpId)
                .orElseGet(ProjectTaskExternalToken::new);

        tokenEntity.setTaskId(taskId);
        tokenEntity.setExtEmpId(extEmpId);
        tokenEntity.setToken(tokenStr);
        tokenEntity.setExpiryDt(expiryDt);
        tokenEntity.setIsActive(true);
        tokenEntity.setCreatedAt(LocalDateTime.now());

        ProjectTaskExternalToken saved = tokenRepository.save(tokenEntity);

        // Fetch Project details for email
        String prjNm = "Bionova Project";
        if (task.getMId() != null) {
            MilestoneLive ms = milestoneLiveRepository.findById(task.getMId()).orElse(null);
            if (ms != null && ms.getPrjId() != null) {
                ProjectLive prj = projectLiveRepository.findById(ms.getPrjId()).orElse(null);
                if (prj != null && prj.getPrjNm() != null) {
                    prjNm = prj.getPrjNm();
                }
            }
        }

        String cleanBaseUrl = (baseUrl != null && !baseUrl.trim().isEmpty()) ? baseUrl.trim() : "http://localhost:5173";
        if (cleanBaseUrl.endsWith("/")) {
            cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length() - 1);
        }
        String magicLink = cleanBaseUrl + "/external-task/" + tokenStr;

        emailService.sendExternalTaskAssignmentEmail(
                extEmp.getEmail(),
                extEmp.getExtEmpNm(),
                task.getTaskNm(),
                prjNm,
                magicLink,
                expiryDt
        );

        return saved;
    }

    /**
     * Admin grants additional days to an external employee when task due date has passed.
     */
    @Transactional
    public ProjectTaskExternalToken extendTaskToken(Long taskId, int additionalDays, String remarks) {
        if (taskId == null || additionalDays <= 0) {
            throw new IllegalArgumentException("Valid task ID and additional days (> 0) required.");
        }

        TaskLive task = taskLiveRepository.findById(taskId)
                .orElseThrow(() -> new NoSuchElementException("Task not found: " + taskId));

        if (!"EXTERNAL".equalsIgnoreCase(task.getTaskAsgnTo()) || task.getExtEmpId() == null) {
            throw new IllegalStateException("This task is not assigned to an external employee.");
        }

        ExternalEmployee extEmp = externalEmployeeRepository.findById(task.getExtEmpId())
                .orElseThrow(() -> new NoSuchElementException("External employee not found: " + task.getExtEmpId()));

        List<ProjectTaskExternalToken> tokens = tokenRepository.findByTaskId(taskId);
        ProjectTaskExternalToken tokenEntity;
        if (tokens.isEmpty()) {
            tokenEntity = new ProjectTaskExternalToken();
            tokenEntity.setTaskId(taskId);
            tokenEntity.setExtEmpId(task.getExtEmpId());
            tokenEntity.setToken(UUID.randomUUID().toString().replace("-", "") + UUID.randomUUID().toString().substring(0, 8));
            tokenEntity.setCreatedAt(LocalDateTime.now());
        } else {
            tokenEntity = tokens.get(0);
        }

        // Extend starting from current time or current expiry, whichever is later
        LocalDateTime base = (tokenEntity.getExpiryDt() != null && tokenEntity.getExpiryDt().isAfter(LocalDateTime.now()))
                ? tokenEntity.getExpiryDt()
                : LocalDateTime.now();

        LocalDateTime newExpiry = base.plusDays(additionalDays).withHour(23).withMinute(59).withSecond(59);
        tokenEntity.setExpiryDt(newExpiry);
        tokenEntity.setIsActive(true);

        ProjectTaskExternalToken saved = tokenRepository.save(tokenEntity);

        // Fetch Project details for email
        String prjNm = "Bionova Project";
        if (task.getMId() != null) {
            MilestoneLive ms = milestoneLiveRepository.findById(task.getMId()).orElse(null);
            if (ms != null && ms.getPrjId() != null) {
                ProjectLive prj = projectLiveRepository.findById(ms.getPrjId()).orElse(null);
                if (prj != null && prj.getPrjNm() != null) {
                    prjNm = prj.getPrjNm();
                }
            }
        }

        String cleanBaseUrl = (baseUrl != null && !baseUrl.trim().isEmpty()) ? baseUrl.trim() : "http://localhost:5173";
        if (cleanBaseUrl.endsWith("/")) {
            cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length() - 1);
        }
        String magicLink = cleanBaseUrl + "/external-task/" + saved.getToken();

        emailService.sendExternalTaskExtensionEmail(
                extEmp.getEmail(),
                extEmp.getExtEmpNm(),
                task.getTaskNm(),
                prjNm,
                magicLink,
                newExpiry,
                additionalDays,
                remarks
        );

        return saved;
    }

    /**
     * Fetch task details for the external employee using their unique magic link token.
     * Evaluates expiration due to:
     *  1. Task Closed / Completed status
     *  2. Due Date / Expiration timestamp passed
     *  3. Admin deactivation
     */
    @Transactional
    public ExternalTaskViewDto getTaskByToken(String tokenStr) {
        if (tokenStr == null || tokenStr.trim().isEmpty()) {
            throw new IllegalArgumentException("Token is required");
        }

        ProjectTaskExternalToken token = tokenRepository.findByToken(tokenStr.trim())
                .orElseThrow(() -> new NoSuchElementException("Invalid or unrecognized task link"));

        TaskLive task = taskLiveRepository.findById(token.getTaskId())
                .orElseThrow(() -> new NoSuchElementException("Associated task not found"));

        ExternalEmployee extEmp = externalEmployeeRepository.findById(token.getExtEmpId()).orElse(null);

        // Expiry evaluation
        boolean isTaskClosed = task.getTaskSts() != null &&
                ("CLOSED".equalsIgnoreCase(task.getTaskSts().getStatusNm()) ||
                 "COMPLETED".equalsIgnoreCase(task.getTaskSts().getStatusNm()));

        boolean isDateExpired = token.getExpiryDt() != null && LocalDateTime.now().isAfter(token.getExpiryDt());
        boolean isInactive = Boolean.FALSE.equals(token.getIsActive());

        boolean isExpired = isTaskClosed || isDateExpired || isInactive;
        String expiredReason = null;
        String expiredMessage = null;

        if (isTaskClosed) {
            expiredReason = "TASK_CLOSED";
            expiredMessage = "This task has been marked as Completed / Closed. Further edits via this link are locked.";
        } else if (isDateExpired) {
            expiredReason = "DUE_DATE_PASSED";
            expiredMessage = "The scheduled due date for this task has passed. Access link has expired. Please contact your Project Administrator if you need an extension.";
        } else if (isInactive) {
            expiredReason = "INACTIVE";
            expiredMessage = "This task link has been deactivated by the administrator.";
        }

        // Fetch Milestone and Project info
        String mlstnTtl = null;
        String mlstnCd = null;
        Long prjId = null;
        String prjNm = null;
        String prjCd = null;

        if (task.getMId() != null) {
            MilestoneLive ms = milestoneLiveRepository.findById(task.getMId()).orElse(null);
            if (ms != null) {
                mlstnTtl = ms.getMlstnTtl();
                mlstnCd = ms.getMlstnCd();
                prjId = ms.getPrjId();
                if (prjId != null) {
                    ProjectLive prj = projectLiveRepository.findById(prjId).orElse(null);
                    if (prj != null) {
                        prjNm = prj.getPrjNm();
                        prjCd = prj.getPrjCd();
                    }
                }
            }
        }

        // Fetch Live Checklists
        List<ExternalTaskViewDto.ChecklistItemDto> checklists = checklistMasterRepository
                .findByTaskIdAndIsLive(task.getTaskId(), true)
                .stream()
                .map(c -> ExternalTaskViewDto.ChecklistItemDto.builder()
                        .chkId(c.getChkId())
                        .chkCd(c.getChkCd())
                        .chkNm(c.getChkNm())
                        .chkDesc(c.getChkDesc())
                        .chkSts(Boolean.TRUE.equals(c.getChkSts()))
                        .build())
                .collect(Collectors.toList());

        // Fetch Live Attachments
        List<ExternalTaskViewDto.AttachmentItemDto> attachments = attachmentMasterRepository
                .findByTIdAndIsLive(task.getTaskId(), true)
                .stream()
                .map(a -> ExternalTaskViewDto.AttachmentItemDto.builder()
                        .fileId(a.getFileId())
                        .fileNm(a.getFileNm())
                        .atPath(a.getAtPath())
                        .atType(a.getAtType())
                        .build())
                .collect(Collectors.toList());

        // Update last accessed timestamp
        token.setLastAccessedAt(LocalDateTime.now());
        tokenRepository.save(token);

        String priorityName = task.getPriority() != null ? task.getPriority().getPriorityNm() : "Low";
        String statusName = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "OPEN";

        boolean isSeqLocked = false;
        String lockReason = null;
        if (!projectStatusCascadeService.isTaskPrerequisitesMet(task)) {
            isSeqLocked = true;
            if (Boolean.TRUE.equals(task.getTaskDepFlg()) && "SEQUENTIAL".equalsIgnoreCase(task.getTaskDepTyp()) && task.getDepTaskId() != null) {
                TaskLive pred = taskLiveRepository.findById(task.getDepTaskId()).orElse(null);
                if (pred != null) {
                    lockReason = "Waiting for predecessor task " + (pred.getTaskCd() != null ? pred.getTaskCd() : "") + " to be completed.";
                }
            } else if (task.getMId() != null) {
                MilestoneLive ms = milestoneLiveRepository.findById(task.getMId()).orElse(null);
                if (ms != null && ms.getMlstnDepMId() != null) {
                    MilestoneLive predMs = milestoneLiveRepository.findById(ms.getMlstnDepMId()).orElse(null);
                    if (predMs != null) {
                        lockReason = "Waiting for predecessor milestone " + (predMs.getMlstnCd() != null ? predMs.getMlstnCd() : "") + " to be closed.";
                    }
                }
            }
        }

        // Fetch Process Config (Reviewer / Approver)
        Long reviewerId = null;
        String reviewerNm = null;
        Long approverId = null;
        String approverNm = null;

        List<ProcessConfig> configs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(task.getTaskId(), true);
        if (configs == null || configs.isEmpty()) {
            configs = processConfigRepository.findByTaskIdOrderByOrdrIdAsc(task.getTaskId());
        }
        for (ProcessConfig pc : configs) {
            boolean isRev = false;
            boolean isApp = false;
            if (pc.getRId() != null) {
                ReviewerMaster rm = reviewerMasterRepository.findById(pc.getRId()).orElse(null);
                if (rm != null) {
                    if ("Reviewer".equalsIgnoreCase(rm.getRNm())) isRev = true;
                    else if ("Approver".equalsIgnoreCase(rm.getRNm())) isApp = true;
                }
            }
            if (!isRev && !isApp) {
                if (pc.getOrdrId() != null && pc.getOrdrId() == 1) isRev = true;
                else if (pc.getOrdrId() != null && pc.getOrdrId() == 2) isApp = true;
            }
            if (isRev && reviewerId == null) {
                reviewerId = pc.getEmpId();
                if (pc.getEmpId() != null) {
                    Employee emp = employeeRepository.findById(pc.getEmpId()).orElse(null);
                    if (emp != null) {
                        reviewerNm = ((emp.getFirstName() != null ? emp.getFirstName() : "") + " " + (emp.getLastName() != null ? emp.getLastName() : "")).trim();
                    }
                }
            } else if (isApp && approverId == null) {
                approverId = pc.getEmpId();
                if (pc.getEmpId() != null) {
                    Employee emp = employeeRepository.findById(pc.getEmpId()).orElse(null);
                    if (emp != null) {
                        approverNm = ((emp.getFirstName() != null ? emp.getFirstName() : "") + " " + (emp.getLastName() != null ? emp.getLastName() : "")).trim();
                    }
                }
            }
        }

        if (reviewerId == null && task.getReviewer() != null) {
            reviewerId = task.getReviewer();
            if (task.getReviewerNm() != null) {
                reviewerNm = task.getReviewerNm();
            } else {
                Employee emp = employeeRepository.findById(reviewerId).orElse(null);
                if (emp != null) {
                    reviewerNm = ((emp.getFirstName() != null ? emp.getFirstName() : "") + " " + (emp.getLastName() != null ? emp.getLastName() : "")).trim();
                }
            }
        }

        if (approverId == null && task.getApprover() != null) {
            approverId = task.getApprover();
            if (task.getApproverNm() != null) {
                approverNm = task.getApproverNm();
            } else {
                Employee emp = employeeRepository.findById(approverId).orElse(null);
                if (emp != null) {
                    approverNm = ((emp.getFirstName() != null ? emp.getFirstName() : "") + " " + (emp.getLastName() != null ? emp.getLastName() : "")).trim();
                }
            }
        }

        return ExternalTaskViewDto.builder()
                .taskId(task.getTaskId())
                .taskCd(task.getTaskCd())
                .taskNm(task.getTaskNm())
                .taskDesc(task.getTaskDesc())
                .prjId(prjId)
                .prjNm(prjNm)
                .prjCd(prjCd)
                .mId(task.getMId())
                .mlstnTtl(mlstnTtl)
                .mlstnCd(mlstnCd)
                .stDt(task.getStDt())
                .endDt(task.getEndDt())
                .noOfDays(task.getNoOfDays())
                .priority(priorityName)
                .taskSts(statusName)
                .subStatus(task.getSubStatus())
                .addlRem(task.getAddlRem())
                .noteTxt(task.getNoteTxt())
                .extEmpId(extEmp != null ? extEmp.getExtEmpId() : null)
                .extEmpNm(extEmp != null ? extEmp.getExtEmpNm() : null)
                .extEmpEmail(extEmp != null ? extEmp.getEmail() : null)
                .companyNm(extEmp != null ? extEmp.getCompanyNm() : null)
                .expiryDt(token.getExpiryDt())
                .isExpired(isExpired)
                .expiredReason(expiredReason)
                .expiredMessage(expiredMessage)
                .isSequentialLocked(isSeqLocked)
                .lockReason(lockReason)
                .reviewerId(reviewerId)
                .reviewerNm(reviewerNm)
                .approverId(approverId)
                .approverNm(approverNm)
                .prcsFlg(task.getPrcsFlg())
                .prcsYesActn(task.getPrcsYesActn())
                .checklists(checklists)
                .attachments(attachments)
                .build();
    }

    /**
     * External employee updates their task status and remarks using their token.
     */
    @Transactional
    public ExternalTaskViewDto updateTask(String tokenStr, ExternalTaskUpdateDto updateDto) {
        if (tokenStr == null || tokenStr.trim().isEmpty()) {
            throw new IllegalArgumentException("Token is required");
        }

        ProjectTaskExternalToken token = tokenRepository.findByToken(tokenStr.trim())
                .orElseThrow(() -> new NoSuchElementException("Invalid task token"));

        TaskLive task = taskLiveRepository.findById(token.getTaskId())
                .orElseThrow(() -> new NoSuchElementException("Task not found"));

        if (task.getTaskSts() != null &&
                ("CLOSED".equalsIgnoreCase(task.getTaskSts().getStatusNm()) ||
                 "COMPLETED".equalsIgnoreCase(task.getTaskSts().getStatusNm()))) {
            throw new IllegalStateException("This task has already been completed and closed.");
        }

        if (token.getExpiryDt() != null && LocalDateTime.now().isAfter(token.getExpiryDt())) {
            throw new IllegalStateException("Task access link has expired past the due date.");
        }

        if (Boolean.FALSE.equals(token.getIsActive())) {
            throw new IllegalStateException("Task link is inactive.");
        }

        if (updateDto.getTaskSts() != null && !updateDto.getTaskSts().trim().isEmpty()) {
            String status = updateDto.getTaskSts().trim().toUpperCase().replace(" ", "_");
            if ("WIP".equals(status) || "SUBMIT_REVIEW".equals(status) || "COMPLETED".equals(status)) {
                if (!projectStatusCascadeService.isTaskPrerequisitesMet(task)) {
                    throw new IllegalStateException("Cannot proceed: Sequential predecessor task/milestone must be completed and closed first.");
                }
            }
            if ("SUBMIT_REVIEW".equals(status) || "UNDER_REVIEW".equals(status)) {
                task.setTaskSts(TaskStatusMaster.WIP);
                task.setSubStatus("Under Review");
                task.setPrcsFlg(true);

                // Determine whether review step should go to PENDING_REVIEWER or PENDING_APPROVER
                Long reviewerId = null;
                Long approverId = null;
                List<ProcessConfig> configs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(task.getTaskId(), true);
                if (configs == null || configs.isEmpty()) {
                    configs = processConfigRepository.findByTaskIdOrderByOrdrIdAsc(task.getTaskId());
                }
                for (ProcessConfig pc : configs) {
                    boolean isRev = false;
                    boolean isApp = false;
                    if (pc.getRId() != null) {
                        ReviewerMaster rm = reviewerMasterRepository.findById(pc.getRId()).orElse(null);
                        if (rm != null) {
                            if ("Reviewer".equalsIgnoreCase(rm.getRNm())) isRev = true;
                            else if ("Approver".equalsIgnoreCase(rm.getRNm())) isApp = true;
                        }
                    }
                    if (!isRev && !isApp) {
                        if (pc.getOrdrId() != null && pc.getOrdrId() == 1) isRev = true;
                        else if (pc.getOrdrId() != null && pc.getOrdrId() == 2) isApp = true;
                    }
                    if (isRev && reviewerId == null) reviewerId = pc.getEmpId();
                    else if (isApp && approverId == null) approverId = pc.getEmpId();
                }
                if (reviewerId == null && task.getReviewer() != null) reviewerId = task.getReviewer();
                if (approverId == null && task.getApprover() != null) approverId = task.getApprover();

                if (reviewerId != null) {
                    task.setPrcsYesActn("PENDING_REVIEWER");
                } else if (approverId != null) {
                    task.setPrcsYesActn("PENDING_APPROVER");
                } else {
                    task.setPrcsYesActn("PENDING_REVIEWER");
                }
            } else {
                task.setTaskSts(TaskStatusMaster.getByName(updateDto.getTaskSts()));
            }
        }

        if (updateDto.getSubStatus() != null) {
            task.setSubStatus(updateDto.getSubStatus());
        }

        if (updateDto.getRemarks() != null && !updateDto.getRemarks().trim().isEmpty()) {
            task.setAddlRem(updateDto.getRemarks());
        }

        taskLiveRepository.save(task);
        projectStatusCascadeService.cascadeStatusFromTask(task.getTaskId());

        return getTaskByToken(tokenStr);
    }

    /**
     * External employee toggles a checklist item on their task.
     */
    @Transactional
    public boolean updateChecklistItem(String tokenStr, Integer chkId, Boolean chkSts) {
        if (tokenStr == null || tokenStr.trim().isEmpty() || chkId == null) {
            return false;
        }

        ProjectTaskExternalToken token = tokenRepository.findByToken(tokenStr.trim())
                .orElseThrow(() -> new NoSuchElementException("Invalid task token"));

        TaskLive task = taskLiveRepository.findById(token.getTaskId())
                .orElseThrow(() -> new NoSuchElementException("Task not found"));

        String taskStatusNm = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
        if ("CLOSED".equalsIgnoreCase(taskStatusNm) || "COMPLETED".equalsIgnoreCase(taskStatusNm)) {
            throw new IllegalStateException("Checklist cannot be edited: Task is already Closed.");
        }

        if (!"WIP".equalsIgnoreCase(taskStatusNm)) {
            throw new IllegalStateException("Checklist cannot be updated: Task has not been started yet. Please click Start to work on this task.");
        }

        if (token.getExpiryDt() != null && LocalDateTime.now().isAfter(token.getExpiryDt())) {
            throw new IllegalStateException("Task link has expired past the due date.");
        }

        ChecklistMaster checklist = checklistMasterRepository.findById(chkId)
                .orElseThrow(() -> new NoSuchElementException("Checklist item not found"));

        if (!token.getTaskId().equals(checklist.getTaskId())) {
            throw new IllegalArgumentException("Checklist item does not belong to this task");
        }

        checklist.setChkSts(chkSts != null && chkSts);
        checklist.setCompletedTs(Boolean.TRUE.equals(chkSts) ? LocalDateTime.now() : null);
        checklistMasterRepository.save(checklist);

        return true;
    }

    /**
     * Retrieve token status info for Admin / PM modal.
     */
    public Map<String, Object> getTokenInfoByTaskId(Long taskId) {
        if (taskId == null) return Map.of();
        TaskLive task = taskLiveRepository.findById(taskId).orElse(null);
        if (task == null) return Map.of();

        List<ProjectTaskExternalToken> tokens = tokenRepository.findByTaskId(taskId);
        if (tokens.isEmpty()) {
            return Map.of(
                    "hasToken", false,
                    "isExternal", "EXTERNAL".equalsIgnoreCase(task.getTaskAsgnTo())
            );
        }

        ProjectTaskExternalToken token = tokens.get(0);
        boolean isTaskClosed = task.getTaskSts() != null &&
                ("CLOSED".equalsIgnoreCase(task.getTaskSts().getStatusNm()) ||
                 "COMPLETED".equalsIgnoreCase(task.getTaskSts().getStatusNm()));
        boolean isDateExpired = token.getExpiryDt() != null && LocalDateTime.now().isAfter(token.getExpiryDt());
        boolean isExpired = isTaskClosed || isDateExpired || Boolean.FALSE.equals(token.getIsActive());

        ExternalEmployee extEmp = task.getExtEmpId() != null ? externalEmployeeRepository.findById(task.getExtEmpId()).orElse(null) : null;

        String cleanBaseUrl = (baseUrl != null && !baseUrl.trim().isEmpty()) ? baseUrl.trim() : "http://localhost:5173";
        if (cleanBaseUrl.endsWith("/")) {
            cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length() - 1);
        }

        Map<String, Object> map = new HashMap<>();
        map.put("hasToken", true);
        map.put("token", token.getToken());
        map.put("magicLink", cleanBaseUrl + "/external-task/" + token.getToken());
        map.put("expiryDt", token.getExpiryDt() != null ? token.getExpiryDt().toString() : "");
        map.put("isActive", token.getIsActive());
        map.put("isExpired", isExpired);
        map.put("isTaskClosed", isTaskClosed);
        map.put("isDateExpired", isDateExpired);
        map.put("extEmpNm", extEmp != null ? extEmp.getExtEmpNm() : "");
        map.put("extEmpEmail", extEmp != null ? extEmp.getEmail() : "");
        map.put("companyNm", extEmp != null ? extEmp.getCompanyNm() : "");
        return map;
    }
}
