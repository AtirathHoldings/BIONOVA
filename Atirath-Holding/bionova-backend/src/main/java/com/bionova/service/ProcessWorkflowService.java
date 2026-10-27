package com.bionova.service;

import com.bionova.entity.*;
import com.bionova.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class ProcessWorkflowService {

    @Autowired private ProcessConfigRepository processConfigRepo;
    @Autowired private ProcessMasterRepository processMasterRepo;
    @Autowired private ReviewerMasterRepository reviewerMasterRepo;
    @Autowired private TaskLiveRepository taskLiveRepo;
    @Autowired private AssignmentRepository assignmentRepo;
    @Autowired private AppNotificationRepository appNotificationRepo;

    public static class ProcessStageInfo {
        public List<Long> reviewerEmpIds = new ArrayList<>();
        public List<Long> approverEmpIds = new ArrayList<>();
        public List<Long> approvedReviewerEmpIds = new ArrayList<>();
        public List<Long> approvedApproverEmpIds = new ArrayList<>();
        public Long activeReviewerId;
        public Integer activeReviewerIndex; // 1-based (Reviewer 1, Reviewer 2, ...)
        public Long activeApproverId;
        public Integer activeApproverIndex; // 1-based (Approver 1, Approver 2, ...)
        public boolean allReviewersApproved = false;
        public boolean allApproversApproved = false;
    }

    public Integer getRoleId(String role) {
        String roleName = "REVIEWER".equalsIgnoreCase(role) ? "Reviewer" : ("EXECUTOR".equalsIgnoreCase(role) ? "Executor" : "Approver");
        return reviewerMasterRepo.findAll().stream()
                .filter(r -> roleName.equalsIgnoreCase(r.getRNm()))
                .findFirst()
                .map(ReviewerMaster::getRId)
                .orElseGet(() -> {
                    ReviewerMaster rm = new ReviewerMaster();
                    rm.setRNm(roleName);
                    rm = reviewerMasterRepo.save(rm);
                    return rm.getRId();
                });
    }

    public ProcessStageInfo calculateStageInfo(Long taskId, boolean isIndividual) {
        ProcessStageInfo info = new ProcessStageInfo();
        if (taskId == null) return info;

        List<ProcessConfig> configs;
        if (isIndividual) {
            configs = processConfigRepo.findByEmpTaskIdOrderByOrdrIdAsc(taskId);
        } else {
            configs = processConfigRepo.findByTaskIdAndIsLiveOrderByOrdrIdAsc(taskId, true);
        }

        Set<Long> seenRev = new LinkedHashSet<>();
        Set<Long> seenApp = new LinkedHashSet<>();

        if (configs != null) {
            for (ProcessConfig pc : configs) {
                if (pc.getEmpId() == null) continue;
                boolean isRev = "REVIEWER".equalsIgnoreCase(pc.getStepType()) || (pc.getRId() != null && pc.getRId() == 1);
                boolean isApp = "APPROVER".equalsIgnoreCase(pc.getStepType()) || (pc.getRId() != null && pc.getRId() == 2);
                if (!isRev && !isApp) {
                    isRev = (pc.getOrdrId() != null && pc.getOrdrId() == 1);
                    isApp = (pc.getOrdrId() != null && pc.getOrdrId() > 1);
                }
                if (isRev) {
                    seenRev.add(pc.getEmpId());
                } else if (isApp) {
                    seenApp.add(pc.getEmpId());
                }
            }
        }
        info.reviewerEmpIds.addAll(seenRev);
        info.approverEmpIds.addAll(seenApp);

        // Fallback to task's reviewer/approver if configs didn't have any
        if (info.reviewerEmpIds.isEmpty()) {
            Long rev = null;
            if (isIndividual) {
                Assignment a = assignmentRepo.findById(taskId).orElse(null);
                if (a != null) rev = a.getReviewer();
            } else {
                TaskLive t = taskLiveRepo.findById(taskId).orElse(null);
                if (t != null) rev = t.getReviewer();
            }
            if (rev != null) info.reviewerEmpIds.add(rev);
        }
        if (info.approverEmpIds.isEmpty()) {
            Long app = null;
            if (isIndividual) {
                Assignment a = assignmentRepo.findById(taskId).orElse(null);
                if (a != null) app = a.getApprover();
            } else {
                TaskLive t = taskLiveRepo.findById(taskId).orElse(null);
                if (t != null) app = t.getApprover();
            }
            if (app != null) info.approverEmpIds.add(app);
        }

        // Inspect history for the current review cycle
        List<ProcessMaster> history;
        if (isIndividual) {
            history = processMasterRepo.findByEmpTaskIdOrderByOrdrIdAsc(taskId);
        } else {
            history = processMasterRepo.findByTaskIdOrderByOrdrIdAsc(taskId);
        }

        int cycleStartIndex = 0;
        Integer executorRId = getRoleId("EXECUTOR");

        for (int i = 0; i < history.size(); i++) {
            ProcessMaster pm = history.get(i);
            // Rejection event resets the cycle
            if ("NO".equalsIgnoreCase(pm.getPrcsSts())) {
                cycleStartIndex = i + 1;
            } else if ("YES".equalsIgnoreCase(pm.getPrcsSts()) && executorRId != null && executorRId.equals(pm.getRId())) {
                // Executor start or submit/resubmit event starts new cycle
                cycleStartIndex = i + 1;
            }
        }

        List<ProcessMaster> cycleHistory = cycleStartIndex < history.size()
                ? history.subList(cycleStartIndex, history.size())
                : List.of();

        for (ProcessMaster pm : cycleHistory) {
            if ("YES".equalsIgnoreCase(pm.getPrcsSts()) && pm.getEmpId() != null) {
                if (info.reviewerEmpIds.contains(pm.getEmpId()) && !info.approvedReviewerEmpIds.contains(pm.getEmpId())) {
                    info.approvedReviewerEmpIds.add(pm.getEmpId());
                } else if (info.approverEmpIds.contains(pm.getEmpId()) && !info.approvedApproverEmpIds.contains(pm.getEmpId())) {
                    info.approvedApproverEmpIds.add(pm.getEmpId());
                }
            }
        }

        // Find active reviewer
        info.allReviewersApproved = info.reviewerEmpIds.isEmpty() ||
                (info.approvedReviewerEmpIds.size() >= info.reviewerEmpIds.size());

        if (!info.allReviewersApproved) {
            for (int i = 0; i < info.reviewerEmpIds.size(); i++) {
                Long rId = info.reviewerEmpIds.get(i);
                if (!info.approvedReviewerEmpIds.contains(rId)) {
                    info.activeReviewerId = rId;
                    info.activeReviewerIndex = i + 1;
                    break;
                }
            }
        }

        // Find active approver (only active once all reviewers have approved)
        info.allApproversApproved = info.approverEmpIds.isEmpty() ||
                (info.approvedApproverEmpIds.size() >= info.approverEmpIds.size());

        if (info.allReviewersApproved && !info.allApproversApproved) {
            for (int i = 0; i < info.approverEmpIds.size(); i++) {
                Long aId = info.approverEmpIds.get(i);
                if (!info.approvedApproverEmpIds.contains(aId)) {
                    info.activeApproverId = aId;
                    info.activeApproverIndex = i + 1;
                    break;
                }
            }
        }

        return info;
    }

    public void populateTaskWorkflowState(TaskLive task) {
        if (task == null || task.getTaskId() == null) return;
        ProcessStageInfo info = calculateStageInfo(task.getTaskId(), false);
        task.setActiveReviewerId(info.activeReviewerId);
        task.setActiveApproverId(info.activeApproverId);
        task.setActiveReviewerIndex(info.activeReviewerIndex);
        task.setActiveApproverIndex(info.activeApproverIndex);
        task.setApprovedReviewerIds(info.approvedReviewerEmpIds);
        task.setApprovedApproverIds(info.approvedApproverEmpIds);

        if ("PENDING_REVIEWER".equalsIgnoreCase(task.getPrcsYesActn()) && info.activeReviewerId != null) {
            task.setReviewer(info.activeReviewerId);
        }
        if ("PENDING_APPROVER".equalsIgnoreCase(task.getPrcsYesActn()) && info.activeApproverId != null) {
            task.setApprover(info.activeApproverId);
        }
    }

    public void populateAssignmentWorkflowState(Assignment task) {
        if (task == null || task.getEmpTaskId() == null) return;
        ProcessStageInfo info = calculateStageInfo(task.getEmpTaskId(), true);
        task.setActiveReviewerId(info.activeReviewerId);
        task.setActiveApproverId(info.activeApproverId);
        task.setActiveReviewerIndex(info.activeReviewerIndex);
        task.setActiveApproverIndex(info.activeApproverIndex);
        task.setApprovedReviewerIds(info.approvedReviewerEmpIds);
        task.setApprovedApproverIds(info.approvedApproverEmpIds);

        if ("PENDING_REVIEWER".equalsIgnoreCase(task.getPrcsYesActn()) && info.activeReviewerId != null) {
            task.setReviewer(info.activeReviewerId);
        }
        if ("PENDING_APPROVER".equalsIgnoreCase(task.getPrcsYesActn()) && info.activeApproverId != null) {
            task.setApprover(info.activeApproverId);
        }
    }

    public void sendAppNotification(Long empId, String entityTyp, Long entityId, String title, String message) {
        if (empId == null) return;
        try {
            AppNotification n = new AppNotification();
            n.setEmpId(empId);
            n.setTitle(title);
            n.setMessage(message);
            n.setEntityTyp(entityTyp);
            n.setEntityId(entityId);
            appNotificationRepo.save(n);
        } catch (Exception e) {
            System.err.println("Failed to send app notification to empId " + empId + ": " + e.getMessage());
        }
    }
}
