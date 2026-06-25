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

    /**
     * Promote a draft project to Live.
     *
     * @param drftPrjId       Draft Project ID
     * @param excludeSat      exclude Saturdays as holidays
     * @param excludeSun      exclude Sundays as holidays
     * @param includeMandatory include public/national holidays
     * @param coyHolidays     include company-specific holidays
     * @param pltHolidays     include plant-specific holidays
     */
    @Transactional
    public Map<String, Object> promoteToLive(
            Long drftPrjId,
            boolean excludeSat,
            boolean excludeSun,
            boolean includeMandatory,
            boolean coyHolidays,
            boolean pltHolidays) {

        // ── 1. Load draft project ──────────────────────────────────────────
        ProjectDraft draft = projectDraftRepository.findById(drftPrjId)
                .orElseThrow(() -> new RuntimeException("Draft Project not found: " + drftPrjId));

        if (projectLiveRepository.findByDrftPrjId(drftPrjId).isPresent()) {
            throw new RuntimeException("This project has already been promoted to Live.");
        }

        Integer coyId = coyHolidays  ? draft.getCoyId() : null;
        Integer pltId = pltHolidays  ? draft.getPltId() : null;

        // ── 2. Create ProjectLive ──────────────────────────────────────────
        ProjectLive live = new ProjectLive();
        live.setDrftPrjId(drftPrjId);
        live.setPrjCd(draft.getPrjCd());
        live.setPrjNm(draft.getPrjNm());
        live.setPrjDesc(draft.getPrjDesc());
        live.setDeptId(draft.getDeptId());
        live.setPrjPrty(draft.getPrjPrty());
        live.setPrjSts("LIVE");
        live.setStDt(draft.getTentStDt());
        live.setEndDt(draft.getTentEndDt());
        live.setNoOfDays(draft.getNoOfDays());
        live.setCoyId(draft.getCoyId());
        live.setPltId(draft.getPltId());
        live.setPrjObjtv(draft.getPrjObjtv());
        live.setExpDlvbls(draft.getExpDlvbls());
        live.setLogo(draft.getLogo());
        live.setAddlRem(draft.getAddlRem());

        // Compute working days for the project range
        int prjWrkDays = calendarService.countWorkingDays(
                draft.getTentStDt(), draft.getTentEndDt(),
                excludeSat, excludeSun, includeMandatory, coyId, pltId);
        live.setWrkDays(prjWrkDays);

        ProjectLive savedProject = projectLiveRepository.save(live);

        // ── 3. Promote Milestones ──────────────────────────────────────────
        List<MilestoneDraft> milestones = milestoneDraftRepository.findByDrftPrjId(drftPrjId);
        int totalMilestones      = 0;
        int totalTasks           = 0;
        int totalChecklists      = 0;
        int totalAttachments     = 0;
        int totalProcessConfigs  = 0;

        for (MilestoneDraft md : milestones) {
            MilestoneLive ml = new MilestoneLive();
            ml.setDrftMId(md.getDrftMId());
            ml.setPrjId(savedProject.getPrjId());
            ml.setMlstnCd(md.getMlstnCd());
            ml.setMlstnTtl(md.getMlstnTtl());
            ml.setMlstnDesc(md.getMlstnDesc());
            ml.setMlstnDays(md.getMlstnDays());
            ml.setMlstnDepFlg(md.getMlstnDepFlg());
            ml.setMlstnDepTyp(md.getMlstnDepTyp());
            ml.setMlstnDepMId(md.getMlstnDepMId());
            ml.setStDt(md.getTentStDt());
            ml.setEndDt(md.getTentEndDt());
            ml.setChkId(md.getChkId());
            ml.setAddlRem(md.getAddlRem());
            ml.setMlstnSts("LIVE");
            ml.setSts(true);

            // Compute milestone working days
            if (md.getTentStDt() != null && md.getTentEndDt() != null) {
                int msWrkDays = calendarService.countWorkingDays(
                        md.getTentStDt(), md.getTentEndDt(),
                        excludeSat, excludeSun, includeMandatory, coyId, pltId);
                ml.setWrkDays(msWrkDays);
            }

            MilestoneLive savedMs = milestoneLiveRepository.save(ml);
            totalMilestones++;

            // ── 4. Promote Tasks for this milestone ────────────────────────
            List<TaskDraft> tasks = taskDraftRepository.findByDrftMId(md.getDrftMId());
            for (TaskDraft td : tasks) {
                TaskLive tl = new TaskLive();
                tl.setDrftTaskId(td.getDrftTaskId());
                tl.setMId(savedMs.getMId());
                tl.setTaskCd(td.getTaskCd());
                tl.setTaskNm(td.getTaskNm());
                tl.setTaskDesc(td.getTaskDesc());
                tl.setTaskAsgnTo(td.getTaskTyp());   // taskTyp maps to task_asgn_to
                tl.setEmpId(td.getEmpId());
                tl.setExtEmpId(td.getExtEmpId());
                tl.setTaskDepFlg(td.getTaskDepFlg());
                tl.setTaskDepTyp(td.getTaskDepTyp());
                tl.setDepTaskId(td.getDepTaskId());
                tl.setNoOfDays(td.getNoOfDays());
                tl.setChkFlg(td.getChkFlg());
                tl.setChkId(td.getChkId());
                tl.setNoteTxt(td.getNoteTxt());
                tl.setStDt(td.getTentStDt());
                tl.setEndDt(td.getTentEndDt());
                tl.setPrcsFlg(td.getPrcsFlg());
                tl.setPrcsYesActn(td.getPrcsYesActn());
                tl.setTaskSts("OPEN");
                tl.setAddlRem(td.getAddlRem());

                // Compute task working days
                if (td.getTentStDt() != null && td.getTentEndDt() != null) {
                    int taskWrkDays = calendarService.countWorkingDays(
                            td.getTentStDt(), td.getTentEndDt(),
                            excludeSat, excludeSun, includeMandatory, coyId, pltId);
                    tl.setWrkDays(taskWrkDays);
                }

                TaskLive savedTask = taskLiveRepository.save(tl);
                totalTasks++;

                // ── 5. Clone Checklists for this task ──────────────────────
                List<ChecklistMaster> draftChecklists =
                        checklistMasterRepository.findByTaskIdAndIsLive(td.getDrftTaskId(), false);
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
                // Draft attachments (reference docs, specs) are linked to the
                // live task so employees can view them during execution.
                List<AttachmentMaster> draftAttachments =
                        attachmentMasterRepository.findByTIdAndIsLive(td.getDrftTaskId(), false);
                for (AttachmentMaster da : draftAttachments) {
                    AttachmentMaster la = new AttachmentMaster();
                    la.setTId(savedTask.getTaskId());
                    la.setIsLive(true);
                    la.setAtPath(da.getAtPath());
                    la.setFileNm(da.getFileNm());
                    la.setAtType(da.getAtType());
                    // dateTimestamp is auto-set by @PrePersist
                    attachmentMasterRepository.save(la);
                    totalAttachments++;
                }

                // ── 7. Clone Process Config steps for this task ──────────────
                // Who is the checker and who is the reviewer — defined in draft,
                // cloned to live so ProcessController can reference them.
                List<ProcessConfig> draftConfigs =
                        processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(td.getDrftTaskId(), false);
                for (ProcessConfig dc : draftConfigs) {
                    ProcessConfig lc = new ProcessConfig();
                    lc.setTaskId(savedTask.getTaskId());
                    lc.setIsLive(true);
                    lc.setOrdrId(dc.getOrdrId());
                    lc.setStepType(dc.getStepType());
                    lc.setEmpId(dc.getEmpId());
                    lc.setRId(dc.getRId());
                    lc.setStepLabel(dc.getStepLabel());
                    processConfigRepository.save(lc);
                    totalProcessConfigs++;
                }
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
}
