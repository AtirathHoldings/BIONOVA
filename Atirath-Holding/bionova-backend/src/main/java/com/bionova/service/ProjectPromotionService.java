package com.bionova.service;

import com.bionova.entity.*;
import com.bionova.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Promotes a ProjectDraft (with its Milestones and Tasks) to Live.
 *
 * Steps:
 *  1. Load the ProjectDraft + all its MilestoneDrafts + TaskDrafts
 *  2. Use CalendarService to compute working days for each
 *  3. Save to project_live_master / milestone_live_master / task_live_master
 *  4. Clone checklist items (isLive=false → isLive=true) per task
 *  5. Clone attachments  (isLive=false → isLive=true) per task
 */
@Service
public class ProjectPromotionService {

    @Autowired private ProjectDraftRepository     projectDraftRepository;
    @Autowired private MilestoneDraftRepository   milestoneDraftRepository;
    @Autowired private TaskDraftRepository        taskDraftRepository;
    @Autowired private ProjectLiveRepository      projectLiveRepository;
    @Autowired private MilestoneLiveRepository    milestoneLiveRepository;
    @Autowired private TaskLiveRepository         taskLiveRepository;
    @Autowired private ChecklistMasterRepository    checklistMasterRepository;
    @Autowired private AttachmentMasterRepository   attachmentMasterRepository;
    @Autowired private ProcessConfigRepository      processConfigRepository;
    @Autowired private CalendarService              calendarService;
    @Autowired private AppNotificationRepository    appNotificationRepository;
    @Autowired private ExternalTaskAccessService    externalTaskAccessService;

    /**
     * Promote a draft project to Live.
     *
     * @param drftPrjId       Draft Project ID
     * @param excludeSat      exclude Saturdays as holidays
     * @param excludeSun      exclude Sundays as holidays
     * @param includeMandatory include public/national holidays
     * @param coyHolidays     include company-specific holidays
     * @param pltHolidays     include plant-specific holidays
     * @param extHolidays     include external-specific holidays
     */
    @Transactional
    public Map<String, Object> promoteToLive(
            Long drftPrjId,
            boolean excludeSat,
            boolean excludeSun,
            boolean includeMandatory,
            boolean coyHolidays,
            boolean pltHolidays,
            boolean extHolidays) {

        // ── 1. Load draft project ──────────────────────────────────────────
        ProjectDraft draft = projectDraftRepository.findById(drftPrjId)
                .orElseThrow(() -> new RuntimeException("Draft Project not found: " + drftPrjId));

        if (projectLiveRepository.findByDrftPrjId(drftPrjId).isPresent()) {
            throw new RuntimeException("This project has already been promoted to Live.");
        }

        // ── Validate: at least 1 milestone and 1 task required ───────────
        long milestoneCount = milestoneDraftRepository.countByDrftPrjId(drftPrjId);
        if (milestoneCount == 0) {
            throw new RuntimeException(
                "Cannot promote to Live: Project has no milestones. " +
                "Please add at least one milestone before going live.");
        }

        long taskCount = taskDraftRepository.countTasksByDrftPrjId(drftPrjId);
        if (taskCount == 0) {
            throw new RuntimeException(
                "Cannot promote to Live: Project has milestones but no tasks. " +
                "Please add at least one task to a milestone before going live.");
        }

        Map<Long, Long> draftToLiveTaskIdMap = new HashMap<>();
        Integer coyId = coyHolidays  ? draft.getCoyId() : null;
        Integer pltId = pltHolidays  ? draft.getPltId() : null;

        // ── 2. Create ProjectLive ──────────────────────────────────────────
        java.time.LocalDate prjAdjustedStartDt = calendarService.getNextWorkingDate(
                draft.getTentStDt(), excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);
        java.time.LocalDate prjAdjustedEndDt = calendarService.calculateEndDate(
                prjAdjustedStartDt, draft.getNoOfDays() != null ? draft.getNoOfDays() : 0,
                excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);

        ProjectLive live = new ProjectLive();
        live.setDrftPrjId(drftPrjId);
        live.setPrjCd(draft.getPrjCd());
        live.setPrjNm(draft.getPrjNm());
        live.setPrjDesc(draft.getPrjDesc());
        live.setDeptId(draft.getDeptId());
        live.setPrjPrty(draft.getPrjPrty());
        live.setPrjSts("LIVE");
        live.setCreatedBy(draft.getCreatedBy());
        live.setStDt(prjAdjustedStartDt != null ? prjAdjustedStartDt : draft.getTentStDt());
        live.setEndDt(prjAdjustedEndDt);
        if (live.getStDt() != null && prjAdjustedEndDt != null) {
            live.setNoOfDays((int) java.time.temporal.ChronoUnit.DAYS.between(live.getStDt(), prjAdjustedEndDt) + 1);
        } else {
            live.setNoOfDays(draft.getNoOfDays());
        }
        live.setCoyId(draft.getCoyId() != null ? draft.getCoyId() : 0);
        live.setPltId(draft.getPltId() != null ? draft.getPltId() : 0);
        live.setPrjObjtv(draft.getPrjObjtv());
        live.setExpDlvbls(draft.getExpDlvbls());
        live.setLogo(draft.getLogo());
        live.setAddlRem(draft.getAddlRem());

        // Compute working days for the project range
        int prjWrkDays = calendarService.countWorkingDaysWithExternal(
                live.getStDt(), prjAdjustedEndDt,
                excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);
        live.setWrkDays(prjWrkDays);

        ProjectLive savedProject = projectLiveRepository.save(live);

        // ── 3. Promote Milestones ──────────────────────────────────────────
        List<MilestoneDraft> milestones = milestoneDraftRepository.findByDrftPrjId(drftPrjId);
        milestones.sort((a, b) -> {
            String cdA = a.getMlstnCd() != null ? a.getMlstnCd() : "";
            String cdB = b.getMlstnCd() != null ? b.getMlstnCd() : "";
            if (!cdA.isEmpty() && !cdB.isEmpty()) {
                int cmp = cdA.compareToIgnoreCase(cdB);
                if (cmp != 0) return cmp;
            }
            if (a.getTentStDt() != null && b.getTentStDt() != null) {
                int cmp = a.getTentStDt().compareTo(b.getTentStDt());
                if (cmp != 0) return cmp;
            }
            return Long.compare(a.getDrftMId() != null ? a.getDrftMId() : 0L, b.getDrftMId() != null ? b.getDrftMId() : 0L);
        });

        Map<Long, MilestoneLive> milestoneLiveMap = new HashMap<>();
        Map<Long, TaskLive> taskLiveMap = new HashMap<>();

        int totalMilestones      = 0;
        int totalTasks           = 0;
        int totalChecklists      = 0;
        int totalAttachments     = 0;
        int totalProcessConfigs  = 0;

        java.time.LocalDate minProjectStart = null;
        java.time.LocalDate maxProjectEnd = null;

        for (MilestoneDraft md : milestones) {
            java.time.LocalDate mStart = md.getTentStDt();
            int mDays = md.getMlstnDays() != null ? md.getMlstnDays() : 1;

            java.time.LocalDate rawMStart = mStart != null ? mStart : savedProject.getStDt();

            // Check explicit dependency
            if (Boolean.TRUE.equals(md.getMlstnDepFlg()) && md.getMlstnDepMId() != null && milestoneLiveMap.containsKey(md.getMlstnDepMId())) {
                MilestoneLive depM = milestoneLiveMap.get(md.getMlstnDepMId());
                if ("PARALLEL".equalsIgnoreCase(md.getMlstnDepTyp())) {
                    rawMStart = depM.getStDt();
                } else {
                    rawMStart = depM.getEndDt() != null ? depM.getEndDt().plusDays(1) : rawMStart;
                }
            } else {
                // Check if sequential based on previous milestones
                java.time.LocalDate maxPrevEnd = null;
                for (MilestoneLive prevML : milestoneLiveMap.values()) {
                    if (prevML.getEndDt() != null) {
                        MilestoneDraft prevMD = milestones.stream().filter(m -> m.getDrftMId().equals(prevML.getDrftMId())).findFirst().orElse(null);
                        if (prevMD != null && prevMD.getTentEndDt() != null && mStart != null && !prevMD.getTentEndDt().isAfter(mStart)) {
                            if (maxPrevEnd == null || prevML.getEndDt().isAfter(maxPrevEnd)) {
                                maxPrevEnd = prevML.getEndDt();
                            }
                        }
                    }
                }
                if (maxPrevEnd != null) {
                    java.time.LocalDate nextDay = maxPrevEnd.plusDays(1);
                    if (mStart == null || nextDay.isAfter(rawMStart)) {
                        rawMStart = nextDay;
                    }
                }
            }

            java.time.LocalDate msAdjustedStartDt = calendarService.getNextWorkingDate(
                    rawMStart, excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);
            java.time.LocalDate msAdjustedEndDt = calendarService.calculateEndDate(
                    msAdjustedStartDt, mDays, excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);

            // ── 4. Promote Tasks for this milestone ────────────────────────
            List<TaskDraft> tasks = taskDraftRepository.findByDrftMId(md.getDrftMId());
            tasks.sort((a, b) -> {
                String cdA = a.getTaskCd() != null ? a.getTaskCd() : "";
                String cdB = b.getTaskCd() != null ? b.getTaskCd() : "";
                if (!cdA.isEmpty() && !cdB.isEmpty()) {
                    int cmp = cdA.compareToIgnoreCase(cdB);
                    if (cmp != 0) return cmp;
                }
                if (a.getTentStDt() != null && b.getTentStDt() != null) {
                    int cmp = a.getTentStDt().compareTo(b.getTentStDt());
                    if (cmp != 0) return cmp;
                }
                return Long.compare(a.getDrftTaskId() != null ? a.getDrftTaskId() : 0L, b.getDrftTaskId() != null ? b.getDrftTaskId() : 0L);
            });

            List<TaskLive> preparedTasksForThisMs = new java.util.ArrayList<>();

            for (TaskDraft td : tasks) {
                java.time.LocalDate tStart = td.getTentStDt();
                int tDays = td.getNoOfDays() != null ? td.getNoOfDays() : 1;

                java.time.LocalDate rawTStart = tStart != null ? tStart : msAdjustedStartDt;
                Long depTaskId = td.getDepTaskId();

                if (Boolean.TRUE.equals(td.getTaskDepFlg()) && depTaskId != null && taskLiveMap.containsKey(depTaskId)) {
                    TaskLive depT = taskLiveMap.get(depTaskId);
                    if ("PARALLEL".equalsIgnoreCase(td.getTaskDepTyp())) {
                        rawTStart = depT.getStDt();
                    } else {
                        rawTStart = depT.getEndDt() != null ? depT.getEndDt().plusDays(1) : rawTStart;
                    }
                } else if (tStart != null) {
                    java.time.LocalDate maxPrevTaskEnd = null;
                    for (TaskLive prevTL : preparedTasksForThisMs) {
                        TaskDraft prevTD = tasks.stream().filter(t -> t.getDrftTaskId().equals(prevTL.getDrftTaskId())).findFirst().orElse(null);
                        if (prevTD != null && prevTD.getTentEndDt() != null && !prevTD.getTentEndDt().isAfter(tStart)) {
                            if (maxPrevTaskEnd == null || prevTL.getEndDt().isAfter(maxPrevTaskEnd)) {
                                maxPrevTaskEnd = prevTL.getEndDt();
                            }
                        }
                    }
                    if (maxPrevTaskEnd != null) {
                        java.time.LocalDate nextDay = maxPrevTaskEnd.plusDays(1);
                        if (nextDay.isAfter(rawTStart)) {
                            rawTStart = nextDay;
                        }
                    } else if (mStart != null && tStart.isAfter(mStart)) {
                        long offset = java.time.temporal.ChronoUnit.DAYS.between(mStart, tStart);
                        java.time.LocalDate candidate = msAdjustedStartDt.plusDays(offset);
                        if (candidate.isAfter(rawTStart)) {
                            rawTStart = candidate;
                        }
                    }
                }

                if (msAdjustedStartDt != null && (rawTStart == null || rawTStart.isBefore(msAdjustedStartDt))) {
                    rawTStart = msAdjustedStartDt;
                }

                java.time.LocalDate taskAdjustedStartDt = calendarService.getNextWorkingDate(
                        rawTStart, excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);
                java.time.LocalDate taskAdjustedEndDt = calendarService.calculateEndDate(
                        taskAdjustedStartDt, tDays, excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);

                TaskLive tl = new TaskLive();
                tl.setDrftTaskId(td.getDrftTaskId());
                tl.setTaskCd(td.getTaskCd());
                tl.setTaskNm(td.getTaskNm());
                tl.setTaskDesc(td.getTaskDesc());
                tl.setTaskAsgnTo(td.getTaskTyp());   // taskTyp maps to task_asgn_to
                tl.setEmpId(td.getEmpId());
                tl.setExtEmpId(td.getExtEmpId());
                tl.setTaskDepFlg(td.getTaskDepFlg());
                tl.setTaskDepTyp(td.getTaskDepTyp());
                tl.setDepTaskId(td.getDepTaskId());
                tl.setChkFlg(td.getChkFlg());
                tl.setNoteTxt(td.getNoteTxt());
                tl.setStDt(taskAdjustedStartDt);
                tl.setEndDt(taskAdjustedEndDt);
                if (taskAdjustedStartDt != null && taskAdjustedEndDt != null) {
                    tl.setNoOfDays((int) java.time.temporal.ChronoUnit.DAYS.between(taskAdjustedStartDt, taskAdjustedEndDt) + 1);
                } else {
                    tl.setNoOfDays(td.getNoOfDays());
                }
                tl.setPrcsFlg(td.getPrcsFlg());
                tl.setPrcsYesActn(td.getPrcsYesActn());
                tl.setTaskSts(TaskStatusMaster.OPEN);
                tl.setPriority(td.getPriority());
                tl.setAddlRem(td.getAddlRem());

                // Compute task working days
                if (taskAdjustedStartDt != null && taskAdjustedEndDt != null) {
                    int taskWrkDays = calendarService.countWorkingDaysWithExternal(
                            taskAdjustedStartDt, taskAdjustedEndDt,
                            excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);
                    tl.setWrkDays(taskWrkDays);
                }

                preparedTasksForThisMs.add(tl);
            }

            // Derive milestone actual start and end dates from child tasks if present
            if (!preparedTasksForThisMs.isEmpty()) {
                java.time.LocalDate minTaskStart = preparedTasksForThisMs.stream().map(TaskLive::getStDt).filter(java.util.Objects::nonNull).min(java.time.LocalDate::compareTo).orElse(msAdjustedStartDt);
                java.time.LocalDate maxTaskEnd = preparedTasksForThisMs.stream().map(TaskLive::getEndDt).filter(java.util.Objects::nonNull).max(java.time.LocalDate::compareTo).orElse(msAdjustedEndDt);
                msAdjustedStartDt = minTaskStart;
                msAdjustedEndDt = maxTaskEnd;
            }

            MilestoneLive ml = new MilestoneLive();
            ml.setDrftMId(md.getDrftMId());
            ml.setPrjId(savedProject.getPrjId());
            ml.setMlstnCd(md.getMlstnCd());
            ml.setMlstnTtl(md.getMlstnTtl());
            ml.setMlstnDesc(md.getMlstnDesc());
            ml.setMlstnDepFlg(md.getMlstnDepFlg());
            ml.setMlstnDepTyp(md.getMlstnDepTyp());
            Long mappedDepMId = md.getMlstnDepMId() != null && milestoneLiveMap.containsKey(md.getMlstnDepMId())
                    ? milestoneLiveMap.get(md.getMlstnDepMId()).getMId()
                    : md.getMlstnDepMId();
            ml.setMlstnDepMId(mappedDepMId);
            ml.setStDt(msAdjustedStartDt);
            ml.setEndDt(msAdjustedEndDt);
            if (msAdjustedStartDt != null && msAdjustedEndDt != null) {
                ml.setMlstnDays((int) java.time.temporal.ChronoUnit.DAYS.between(msAdjustedStartDt, msAdjustedEndDt) + 1);
            } else {
                ml.setMlstnDays(md.getMlstnDays());
            }
            ml.setAddlRem(md.getAddlRem());
            ml.setMlstnSts("LIVE");
            ml.setSts(true);

            // Compute milestone working days
            if (msAdjustedStartDt != null && msAdjustedEndDt != null) {
                int msWrkDays = calendarService.countWorkingDaysWithExternal(
                        msAdjustedStartDt, msAdjustedEndDt,
                        excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);
                ml.setWrkDays(msWrkDays);
            }

            MilestoneLive savedMs = milestoneLiveRepository.save(ml);
            milestoneLiveMap.put(md.getDrftMId(), savedMs);
            totalMilestones++;

            if (minProjectStart == null || (msAdjustedStartDt != null && msAdjustedStartDt.isBefore(minProjectStart))) {
                minProjectStart = msAdjustedStartDt;
            }
            if (maxProjectEnd == null || (msAdjustedEndDt != null && msAdjustedEndDt.isAfter(maxProjectEnd))) {
                maxProjectEnd = msAdjustedEndDt;
            }

            // Save tasks with mId set
            for (TaskLive tl : preparedTasksForThisMs) {
                tl.setMId(savedMs.getMId());
                TaskLive savedTask = taskLiveRepository.save(tl);
                taskLiveMap.put(tl.getDrftTaskId(), savedTask);
                draftToLiveTaskIdMap.put(tl.getDrftTaskId(), savedTask.getTaskId());
                totalTasks++;

                // Generate and email magic link for external employee assignment
                if ("EXTERNAL".equalsIgnoreCase(savedTask.getTaskAsgnTo()) && savedTask.getExtEmpId() != null) {
                    try {
                        externalTaskAccessService.generateOrRefreshToken(savedTask.getTaskId(), savedTask.getExtEmpId());
                    } catch (Exception ex) {
                        System.err.println("Failed to dispatch external task token during promotion for Task ID " + savedTask.getTaskId() + ": " + ex.getMessage());
                    }
                }

                // ── 5. Clone Checklists for this task ──────────────────────
                List<ChecklistMaster> draftChecklists =
                        checklistMasterRepository.findByTaskIdAndIsLive(tl.getDrftTaskId(), false);
                for (ChecklistMaster dc : draftChecklists) {
                    ChecklistMaster lc = new ChecklistMaster();
                    lc.setTaskId(savedTask.getTaskId());
                    lc.setIsLive(true);
                    lc.setChkCd(dc.getChkCd());
                    lc.setChkNm(dc.getChkNm());
                    lc.setChkDesc(dc.getChkDesc());
                    lc.setSeqNo(dc.getSeqNo());
                    lc.setChkSts(false);          // reset — not yet done in live
                    lc.setCompletedTs(null);
                    lc.setSts(dc.getSts());
                    checklistMasterRepository.save(lc);
                    totalChecklists++;
                }

                // ── 6. Clone Attachments for this task ─────────────────────
                List<AttachmentMaster> draftAttachments =
                        attachmentMasterRepository.findByTIdAndIsLive(tl.getDrftTaskId(), false);
                for (AttachmentMaster da : draftAttachments) {
                    AttachmentMaster la = new AttachmentMaster();
                    la.setTId(savedTask.getTaskId());
                    la.setIsLive(true);
                    la.setAtPath(da.getAtPath());
                    la.setFileNm(da.getFileNm());
                    la.setAtType(da.getAtType());
                    attachmentMasterRepository.save(la);
                    totalAttachments++;
                }

                // ── 7. Clone Process Config steps for this task ──────────────
                List<ProcessConfig> draftConfigs =
                        processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(tl.getDrftTaskId(), false);
                for (ProcessConfig dc : draftConfigs) {
                    ProcessConfig lc = new ProcessConfig();
                    lc.setTaskId(savedTask.getTaskId());
                    lc.setIsLive(true);
                    lc.setOrdrId(dc.getOrdrId());
                    lc.setEmpId(dc.getEmpId());
                    lc.setRId(dc.getRId());
                    processConfigRepository.save(lc);
                    totalProcessConfigs++;

                    if (lc.getEmpId() != null) {
                        AppNotification notification = new AppNotification();
                        notification.setEmpId(lc.getEmpId());
                        String role = (lc.getOrdrId() == 1) ? "Reviewer" : "Approver";
                        notification.setTitle("Assigned as " + role + ": " + savedTask.getTaskCd());
                        notification.setMessage("You have been assigned as the " + role + " for task '" + savedTask.getTaskNm() + "'.");
                        notification.setEntityTyp("TASK");
                        notification.setEntityId(savedTask.getTaskId());
                        appNotificationRepository.save(notification);
                    }
                }
            }
        }

        // Update ProjectLive with final adjusted start and end dates if milestones exist
        if (minProjectStart != null) {
            savedProject.setStDt(minProjectStart);
        }
        if (maxProjectEnd != null && (savedProject.getEndDt() == null || maxProjectEnd.isAfter(savedProject.getEndDt()))) {
            savedProject.setEndDt(maxProjectEnd);
        }
        if (savedProject.getStDt() != null && savedProject.getEndDt() != null) {
            savedProject.setNoOfDays((int) java.time.temporal.ChronoUnit.DAYS.between(savedProject.getStDt(), savedProject.getEndDt()) + 1);
            int updatedWrkDays = calendarService.countWorkingDaysWithExternal(
                    savedProject.getStDt(), savedProject.getEndDt(),
                    excludeSat, excludeSun, includeMandatory, coyId, pltId, extHolidays);
            savedProject.setWrkDays(updatedWrkDays);
            savedProject = projectLiveRepository.save(savedProject);
        }

        // ── 7.5. Map depTaskId to Live Task IDs and set status to DRAFT if sequential dependency is pending ──
        for (Map.Entry<Long, Long> entry : draftToLiveTaskIdMap.entrySet()) {
            Long liveTaskId = entry.getValue();
            TaskLive liveTask = taskLiveRepository.findById(liveTaskId).orElse(null);
            if (liveTask != null) {
                if (liveTask.getDepTaskId() != null) {
                    Long liveDepTaskId = draftToLiveTaskIdMap.get(liveTask.getDepTaskId());
                    if (liveDepTaskId != null) {
                        liveTask.setDepTaskId(liveDepTaskId);
                    }
                }

                liveTask.setTaskSts(TaskStatusMaster.OPEN);
                taskLiveRepository.save(liveTask);
            }
        }

        // ── 8. Return summary ──────────────────────────────────────────────
        Map<String, Object> result = new HashMap<>();
        result.put("message", "Project promoted to Live successfully.");
        result.put("prjId", savedProject.getPrjId());
        result.put("prjCd", savedProject.getPrjCd());
        result.put("wrkDays", savedProject.getWrkDays());
        result.put("noOfDays", savedProject.getNoOfDays());
        result.put("milestonesPromoted", totalMilestones);
        result.put("tasksPromoted", totalTasks);
        result.put("checklistsPromoted", totalChecklists);
        result.put("attachmentsPromoted", totalAttachments);
        result.put("processConfigsPromoted", totalProcessConfigs);
        return result;
    }

    // ── Helper methods for pre-flight check ───────────────────────────────

    public boolean isAlreadyLive(Long drftPrjId) {
        return projectLiveRepository.findByDrftPrjId(drftPrjId).isPresent();
    }

    public long countMilestones(Long drftPrjId) {
        return milestoneDraftRepository.countByDrftPrjId(drftPrjId);
    }

    public long countTasks(Long drftPrjId) {
        return taskDraftRepository.countTasksByDrftPrjId(drftPrjId);
    }
}
