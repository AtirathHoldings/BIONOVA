package com.bionova.controller;

import com.bionova.entity.ProjectDraft;
import com.bionova.repository.ProjectDraftRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.temporal.ChronoUnit;
import java.util.List;

@RestController
@RequestMapping("/api/project-drafts")
public class ProjectDraftController {

    @Autowired
    private ProjectDraftRepository projectDraftRepository;

    @Autowired
    private com.bionova.repository.MilestoneDraftRepository milestoneDraftRepository;

    @Autowired
    private com.bionova.repository.TaskDraftRepository taskDraftRepository;

    @Autowired
    private com.bionova.repository.ChecklistMasterRepository checklistMasterRepository;

    @Autowired
    private com.bionova.repository.AttachmentMasterRepository attachmentMasterRepository;

    @Autowired
    private com.bionova.repository.ProcessConfigRepository processConfigRepository;

    @Autowired
    private com.bionova.repository.EmployeeRepository employeeRepository;

    /** GET all drafts */
    @GetMapping
    public List<ProjectDraft> getAll() {
        return projectDraftRepository.findAll();
    }

    /** GET by ID */
    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return projectDraftRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /** GET drafts by company */
    @GetMapping("/by-company/{coyId}")
    public List<ProjectDraft> getByCompany(@PathVariable Integer coyId) {
        return projectDraftRepository.findByCoyId(coyId);
    }

    /** GET drafts by company + plant */
    @GetMapping("/by-company/{coyId}/plant/{pltId}")
    public List<ProjectDraft> getByCompanyAndPlant(
            @PathVariable Integer coyId,
            @PathVariable Integer pltId) {
        return projectDraftRepository.findByCoyIdAndPltId(coyId, pltId);
    }

    /** POST – create new draft (auto-computes no_of_days, sets status DRAFT) */
    @PostMapping
    public ResponseEntity<?> create(@RequestBody ProjectDraft draft) {
        if (draft.getPrjCd() != null && !draft.getPrjCd().trim().isEmpty()) {
            if (projectDraftRepository.existsByPrjCd(draft.getPrjCd())) {
                return ResponseEntity.badRequest().body(java.util.Map.of("message", "Project code already exists."));
            }
        }

        draft.setPrjSts("DRAFT");

        // Auto-populate createdBy if not sent in request body
        if (draft.getCreatedBy() == null) {
            try {
                org.springframework.security.core.Authentication auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
                if (auth != null && auth.getName() != null && !auth.getName().isEmpty() && !"anonymousUser".equals(auth.getName())) {
                    String principal = auth.getName();
                    employeeRepository.findByEmail(principal).ifPresent(emp -> draft.setCreatedBy(emp.getEmpId()));
                }
            } catch (Exception ignored) {}
        }

        // Auto-compute tentative days (inclusive: start=day1, so Jul2→Jul26 = 25 days)
        if (draft.getTentStDt() != null && draft.getTentEndDt() != null) {
            long days = ChronoUnit.DAYS.between(draft.getTentStDt(), draft.getTentEndDt()) + 1;
            draft.setNoOfDays((int) days);
        }

        ProjectDraft saved = projectDraftRepository.save(draft);
        return ResponseEntity.ok(saved);
    }

    /** PUT – update draft */
    @PutMapping("/{id}")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<?> update(
            @PathVariable Long id,
            @RequestBody ProjectDraft details) {

        ProjectDraft draft = projectDraftRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Draft not found: " + id));

        java.time.LocalDate oldStart = draft.getTentStDt();
        java.time.LocalDate newStart = details.getTentStDt();

        if (details.getPrjCd() != null && !details.getPrjCd().trim().isEmpty()) {
            if (projectDraftRepository.existsByPrjCdAndDrftPrjIdNot(details.getPrjCd(), id)) {
                return ResponseEntity.badRequest().body(java.util.Map.of("message", "Project code already exists."));
            }
            draft.setPrjCd(details.getPrjCd());
        }

        draft.setPrjNm(details.getPrjNm());
        draft.setPrjDesc(details.getPrjDesc());
        draft.setDeptId(details.getDeptId());
        draft.setPrjPrty(details.getPrjPrty());
        draft.setTentStDt(details.getTentStDt());
        draft.setTentEndDt(details.getTentEndDt());
        draft.setCoyId(details.getCoyId());
        draft.setPltId(details.getPltId());
        draft.setPrjObjtv(details.getPrjObjtv());
        draft.setExpDlvbls(details.getExpDlvbls());
        draft.setLogo(details.getLogo());
        draft.setAddlRem(details.getAddlRem());

        // Recompute no_of_days (inclusive: start=day1, so Jul2→Jul26 = 25 days)
        if (draft.getTentStDt() != null && draft.getTentEndDt() != null) {
            long days = ChronoUnit.DAYS.between(draft.getTentStDt(), draft.getTentEndDt()) + 1;
            draft.setNoOfDays((int) days);
        }

        ProjectDraft saved = projectDraftRepository.save(draft);

        // Shift milestones and tasks if project start date changed or if they are out of sync
        if (saved.getTentStDt() != null) {
            long shiftDays = 0;
            if (oldStart != null && newStart != null) {
                shiftDays = java.time.temporal.ChronoUnit.DAYS.between(oldStart, newStart);
            }
            
            List<com.bionova.entity.MilestoneDraft> milestones = milestoneDraftRepository.findByDrftPrjId(id);
            for (com.bionova.entity.MilestoneDraft milestone : milestones) {
                long finalMilestoneShift = shiftDays;
                if (milestone.getTentStDt() != null && milestone.getTentStDt().isBefore(saved.getTentStDt())) {
                    // Force shift to align with project start date if it starts before project
                    finalMilestoneShift = java.time.temporal.ChronoUnit.DAYS.between(milestone.getTentStDt(), saved.getTentStDt());
                }
                
                if (finalMilestoneShift != 0) {
                    if (milestone.getTentStDt() != null) {
                        milestone.setTentStDt(milestone.getTentStDt().plusDays(finalMilestoneShift));
                    }
                    if (milestone.getTentEndDt() != null) {
                        milestone.setTentEndDt(milestone.getTentEndDt().plusDays(finalMilestoneShift));
                    }
                    milestoneDraftRepository.save(milestone);
                }
                
                List<com.bionova.entity.TaskDraft> tasks = taskDraftRepository.findByDrftMId(milestone.getDrftMId());
                for (com.bionova.entity.TaskDraft task : tasks) {
                    long finalTaskShift = finalMilestoneShift;
                    if (task.getTentStDt() != null && milestone.getTentStDt() != null && task.getTentStDt().isBefore(milestone.getTentStDt())) {
                        finalTaskShift = java.time.temporal.ChronoUnit.DAYS.between(task.getTentStDt(), milestone.getTentStDt());
                    }
                    
                    if (finalTaskShift != 0) {
                        if (task.getTentStDt() != null) {
                            task.setTentStDt(task.getTentStDt().plusDays(finalTaskShift));
                        }
                        if (task.getTentEndDt() != null) {
                            task.setTentEndDt(task.getTentEndDt().plusDays(finalTaskShift));
                        }
                        taskDraftRepository.save(task);
                    }
                }
            }
        }

        // Validate if any milestones or tasks exceed new project limits
        String warning = null;
        List<com.bionova.entity.MilestoneDraft> milestones = milestoneDraftRepository.findByDrftPrjId(id);
        for (com.bionova.entity.MilestoneDraft milestone : milestones) {
            if (milestone.getTentStDt() != null && milestone.getTentEndDt() != null) {
                if (milestone.getTentStDt().isBefore(saved.getTentStDt()) ||
                    milestone.getTentEndDt().isAfter(saved.getTentEndDt()) ||
                    (milestone.getMlstnDays() != null && saved.getNoOfDays() != null && milestone.getMlstnDays() > saved.getNoOfDays())) {
                    warning = "Warning: Some milestones or tasks now exceed the updated project limits. Please review and update them accordingly.";
                    break;
                }
            }
            
            // Check tasks of this milestone
            List<com.bionova.entity.TaskDraft> tasks = taskDraftRepository.findByDrftMId(milestone.getDrftMId());
            for (com.bionova.entity.TaskDraft task : tasks) {
                if (task.getTentStDt() != null && task.getTentEndDt() != null) {
                    if (task.getTentStDt().isBefore(saved.getTentStDt()) ||
                        task.getTentEndDt().isAfter(saved.getTentEndDt()) ||
                        (task.getNoOfDays() != null && saved.getNoOfDays() != null && task.getNoOfDays() > saved.getNoOfDays())) {
                        warning = "Warning: Some milestones or tasks now exceed the updated project limits. Please review and update them accordingly.";
                        break;
                    }
                }
            }
            if (warning != null) {
                break;
            }
        }

        java.util.Map<String, Object> response = new java.util.HashMap<>();
        response.put("data", saved);
        if (warning != null) {
            response.put("warning", warning);
        }
        return ResponseEntity.ok(response);
    }

    /** DELETE */
    @DeleteMapping("/{id}")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        List<com.bionova.entity.MilestoneDraft> milestones = milestoneDraftRepository.findByDrftPrjId(id);
        for (com.bionova.entity.MilestoneDraft milestone : milestones) {
            List<com.bionova.entity.TaskDraft> tasks = taskDraftRepository.findByDrftMId(milestone.getDrftMId());
            for (com.bionova.entity.TaskDraft task : tasks) {
                // Delete task checklists
                List<com.bionova.entity.ChecklistMaster> checklists = checklistMasterRepository.findByTaskIdAndIsLive(task.getDrftTaskId(), false);
                checklistMasterRepository.deleteAll(checklists);

                // Delete task attachments
                List<com.bionova.entity.AttachmentMaster> attachments = attachmentMasterRepository.findByTIdAndIsLive(task.getDrftTaskId(), false);
                attachmentMasterRepository.deleteAll(attachments);

                // Delete task process configs
                List<com.bionova.entity.ProcessConfig> processConfigs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(task.getDrftTaskId(), false);
                processConfigRepository.deleteAll(processConfigs);

                // Delete task
                taskDraftRepository.delete(task);
            }
            // Delete milestone
            milestoneDraftRepository.delete(milestone);
        }
        // Delete project draft itself
        projectDraftRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    /** POST – duplicate a project draft with all its milestones, tasks, checklists, attachments, process configs */
    @PostMapping("/{id}/duplicate")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<?> duplicateDraft(@PathVariable Long id) {
        ProjectDraft source = projectDraftRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Source project draft not found: " + id));

        // 1. Generate next project code
        List<ProjectDraft> allDrafts = projectDraftRepository.findAll();
        int maxNum = 0;
        for (ProjectDraft p : allDrafts) {
            if (p.getPrjCd() != null) {
                java.util.regex.Matcher m = java.util.regex.Pattern.compile("^PRJ[-_]?(\\d+)$", java.util.regex.Pattern.CASE_INSENSITIVE).matcher(p.getPrjCd());
                if (m.find()) {
                    try {
                        int num = Integer.parseInt(m.group(1));
                        if (num < 2000 && num > maxNum) maxNum = num;
                    } catch (Exception ignored) {}
                }
            }
        }
        String nextCode = String.format("PRJ-%03d", maxNum + 1);

        // 2. Clone ProjectDraft
        ProjectDraft newDraft = new ProjectDraft();
        newDraft.setPrjCd(nextCode);
        newDraft.setPrjNm(source.getPrjNm() + " (Copy)");
        newDraft.setPrjDesc(source.getPrjDesc());
        newDraft.setDeptId(source.getDeptId());
        newDraft.setPrjPrty(source.getPrjPrty());
        newDraft.setPrjSts("DRAFT");
        newDraft.setTentStDt(source.getTentStDt());
        newDraft.setTentEndDt(source.getTentEndDt());
        newDraft.setNoOfDays(source.getNoOfDays());
        newDraft.setCoyId(source.getCoyId());
        newDraft.setPltId(source.getPltId());
        newDraft.setPrjObjtv(source.getPrjObjtv());
        newDraft.setExpDlvbls(source.getExpDlvbls());
        newDraft.setLogo(source.getLogo());
        newDraft.setAddlRem(source.getAddlRem());
        newDraft.setCreatedBy(source.getCreatedBy());

        ProjectDraft savedDraft = projectDraftRepository.save(newDraft);

        // 3. Clone Milestones
        List<com.bionova.entity.MilestoneDraft> milestones = milestoneDraftRepository.findByDrftPrjId(id);
        java.util.Map<Long, Long> milestoneIdMap = new java.util.HashMap<>();

        for (com.bionova.entity.MilestoneDraft oldM : milestones) {
            com.bionova.entity.MilestoneDraft newM = new com.bionova.entity.MilestoneDraft();
            newM.setDrftPrjId(savedDraft.getDrftPrjId());
            newM.setMlstnCd(oldM.getMlstnCd());
            newM.setMlstnTtl(oldM.getMlstnTtl());
            newM.setMlstnDesc(oldM.getMlstnDesc());
            newM.setMlstnDays(oldM.getMlstnDays());
            newM.setMlstnDepFlg(oldM.getMlstnDepFlg());
            newM.setMlstnDepTyp(oldM.getMlstnDepTyp());
            newM.setTentStDt(oldM.getTentStDt());
            newM.setTentEndDt(oldM.getTentEndDt());
            newM.setFileUrl(oldM.getFileUrl());
            newM.setAddlRem(oldM.getAddlRem());
            newM.setMlstnSts("DRAFT");
            newM.setSts(true);

            com.bionova.entity.MilestoneDraft savedM = milestoneDraftRepository.save(newM);
            milestoneIdMap.put(oldM.getDrftMId(), savedM.getDrftMId());
        }

        // Fix milestone dependencies (mlstnDepMId)
        for (com.bionova.entity.MilestoneDraft oldM : milestones) {
            if (Boolean.TRUE.equals(oldM.getMlstnDepFlg()) && oldM.getMlstnDepMId() != null) {
                Long newDepMId = milestoneIdMap.get(oldM.getMlstnDepMId());
                Long newMId = milestoneIdMap.get(oldM.getDrftMId());
                if (newMId != null && newDepMId != null) {
                    milestoneDraftRepository.findById(newMId).ifPresent(mToUpdate -> {
                        mToUpdate.setMlstnDepMId(newDepMId);
                        milestoneDraftRepository.save(mToUpdate);
                    });
                }
            }
        }

        // 4. Clone Tasks for each milestone
        for (com.bionova.entity.MilestoneDraft oldM : milestones) {
            Long newMId = milestoneIdMap.get(oldM.getDrftMId());
            if (newMId == null) continue;

            List<com.bionova.entity.TaskDraft> tasks = taskDraftRepository.findByDrftMId(oldM.getDrftMId());
            java.util.Map<Long, Long> taskIdMap = new java.util.HashMap<>();

            for (com.bionova.entity.TaskDraft oldT : tasks) {
                com.bionova.entity.TaskDraft newT = new com.bionova.entity.TaskDraft();
                newT.setDrftMId(newMId);
                newT.setTaskCd(oldT.getTaskCd());
                newT.setTaskNm(oldT.getTaskNm());
                newT.setTaskDesc(oldT.getTaskDesc());
                newT.setTaskTyp(oldT.getTaskTyp());
                newT.setEmpId(oldT.getEmpId());
                newT.setExtEmpId(oldT.getExtEmpId());
                newT.setTaskDepFlg(oldT.getTaskDepFlg());
                newT.setTaskDepTyp(oldT.getTaskDepTyp());
                newT.setNoOfDays(oldT.getNoOfDays());
                newT.setChkFlg(oldT.getChkFlg());
                newT.setFilePath(oldT.getFilePath());
                newT.setNoteTxt(oldT.getNoteTxt());
                newT.setTentStDt(oldT.getTentStDt());
                newT.setTentEndDt(oldT.getTentEndDt());
                newT.setPrcsFlg(oldT.getPrcsFlg());
                newT.setPrcsYesActn(oldT.getPrcsYesActn());
                newT.setTaskSts(oldT.getTaskSts());
                newT.setSubStatus(oldT.getSubStatus());
                newT.setPriority(oldT.getPriority());
                newT.setAddlRem(oldT.getAddlRem());
                newT.setSts(true);

                com.bionova.entity.TaskDraft savedT = taskDraftRepository.save(newT);
                taskIdMap.put(oldT.getDrftTaskId(), savedT.getDrftTaskId());

                // Clone Checklists
                List<com.bionova.entity.ChecklistMaster> checklists = checklistMasterRepository.findByTaskIdAndIsLive(oldT.getDrftTaskId(), false);
                for (com.bionova.entity.ChecklistMaster oldC : checklists) {
                    com.bionova.entity.ChecklistMaster newC = new com.bionova.entity.ChecklistMaster();
                    newC.setTaskId(savedT.getDrftTaskId());
                    newC.setChkCd(oldC.getChkCd());
                    newC.setChkNm(oldC.getChkNm());
                    newC.setChkDesc(oldC.getChkDesc());
                    newC.setChkSts(oldC.getChkSts());
                    newC.setSeqNo(oldC.getSeqNo());
                    newC.setSts(oldC.getSts());
                    newC.setIsLive(false);
                    checklistMasterRepository.save(newC);
                }

                // Clone Attachments
                List<com.bionova.entity.AttachmentMaster> attachments = attachmentMasterRepository.findByTIdAndIsLive(oldT.getDrftTaskId(), false);
                for (com.bionova.entity.AttachmentMaster oldA : attachments) {
                    com.bionova.entity.AttachmentMaster newA = new com.bionova.entity.AttachmentMaster();
                    newA.setTId(savedT.getDrftTaskId());
                    newA.setRefId(savedT.getDrftTaskId());
                    newA.setRefType("TASK_DRAFT");
                    newA.setFileNm(oldA.getFileNm());
                    newA.setAtPath(oldA.getAtPath());
                    newA.setAtType(oldA.getAtType());
                    newA.setIsLive(false);
                    attachmentMasterRepository.save(newA);
                }

                // Clone ProcessConfigs
                List<com.bionova.entity.ProcessConfig> processConfigs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(oldT.getDrftTaskId(), false);
                for (com.bionova.entity.ProcessConfig oldP : processConfigs) {
                    com.bionova.entity.ProcessConfig newP = new com.bionova.entity.ProcessConfig();
                    newP.setTaskId(savedT.getDrftTaskId());
                    newP.setOrdrId(oldP.getOrdrId());
                    newP.setEmpId(oldP.getEmpId());
                    newP.setRId(oldP.getRId());
                    newP.setExtEmpId(oldP.getExtEmpId());
                    newP.setEmpTaskId(oldP.getEmpTaskId());
                    newP.setIsLive(false);
                    processConfigRepository.save(newP);
                }
            }

            // Fix task dependencies
            for (com.bionova.entity.TaskDraft oldT : tasks) {
                if (Boolean.TRUE.equals(oldT.getTaskDepFlg()) && oldT.getDepTaskId() != null) {
                    Long newDepTaskId = taskIdMap.get(oldT.getDepTaskId());
                    Long newTaskId = taskIdMap.get(oldT.getDrftTaskId());
                    if (newTaskId != null && newDepTaskId != null) {
                        taskDraftRepository.findById(newTaskId).ifPresent(tToUpdate -> {
                            tToUpdate.setDepTaskId(newDepTaskId);
                            taskDraftRepository.save(tToUpdate);
                        });
                    }
                }
            }
        }

        return ResponseEntity.ok(savedDraft);
    }
}
