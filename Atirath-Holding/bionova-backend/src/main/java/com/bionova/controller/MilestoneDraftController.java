package com.bionova.controller;

import com.bionova.entity.MilestoneDraft;
import com.bionova.entity.ProjectDraft;
import com.bionova.entity.TaskDraft;
import com.bionova.repository.MilestoneDraftRepository;
import com.bionova.repository.ProjectDraftRepository;
import com.bionova.repository.TaskDraftRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/milestone-drafts")
public class MilestoneDraftController {

    @Autowired
    private MilestoneDraftRepository milestoneDraftRepository;

    @Autowired
    private ProjectDraftRepository projectDraftRepository;

    @Autowired
    private TaskDraftRepository taskDraftRepository;

    @Autowired
    private com.bionova.repository.ChecklistMasterRepository checklistMasterRepository;

    @Autowired
    private com.bionova.repository.AttachmentMasterRepository attachmentMasterRepository;

    @Autowired
    private com.bionova.repository.ProcessConfigRepository processConfigRepository;

    @GetMapping
    @org.springframework.transaction.annotation.Transactional
    public List<MilestoneDraft> getAll() {
        List<MilestoneDraft> milestones = milestoneDraftRepository.findAll();
        boolean updatedAny = false;
        for (MilestoneDraft milestone : milestones) {
            ProjectDraft project = projectDraftRepository.findById(milestone.getDrftPrjId()).orElse(null);
            if (project != null && project.getTentStDt() != null) {
                long finalMilestoneShift = 0;
                if (milestone.getTentStDt() != null && milestone.getTentStDt().isBefore(project.getTentStDt())) {
                    finalMilestoneShift = java.time.temporal.ChronoUnit.DAYS.between(milestone.getTentStDt(), project.getTentStDt());
                }
                
                if (finalMilestoneShift != 0) {
                    if (milestone.getTentStDt() != null) {
                        milestone.setTentStDt(milestone.getTentStDt().plusDays(finalMilestoneShift));
                    }
                    if (milestone.getTentEndDt() != null) {
                        milestone.setTentEndDt(milestone.getTentEndDt().plusDays(finalMilestoneShift));
                    }
                    milestoneDraftRepository.save(milestone);
                    updatedAny = true;
                }
                
                List<TaskDraft> tasks = taskDraftRepository.findByDrftMId(milestone.getDrftMId());
                for (TaskDraft task : tasks) {
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
        if (updatedAny) {
            milestones = milestoneDraftRepository.findAll();
        }
        return milestones;
    }

    @GetMapping("/{id}")
    public ResponseEntity<MilestoneDraft> getById(@PathVariable Long id) {
        return milestoneDraftRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-project/{prjId}")
    @org.springframework.transaction.annotation.Transactional
    public List<MilestoneDraft> getByProject(@PathVariable Long prjId) {
        ProjectDraft project = projectDraftRepository.findById(prjId).orElse(null);
        List<MilestoneDraft> milestones = milestoneDraftRepository.findByDrftPrjId(prjId);
        if (project != null && project.getTentStDt() != null) {
            boolean updatedAny = false;
            for (MilestoneDraft milestone : milestones) {
                long finalMilestoneShift = 0;
                if (milestone.getTentStDt() != null && milestone.getTentStDt().isBefore(project.getTentStDt())) {
                    finalMilestoneShift = java.time.temporal.ChronoUnit.DAYS.between(milestone.getTentStDt(), project.getTentStDt());
                }
                
                if (finalMilestoneShift != 0) {
                    if (milestone.getTentStDt() != null) {
                        milestone.setTentStDt(milestone.getTentStDt().plusDays(finalMilestoneShift));
                    }
                    if (milestone.getTentEndDt() != null) {
                        milestone.setTentEndDt(milestone.getTentEndDt().plusDays(finalMilestoneShift));
                    }
                    milestoneDraftRepository.save(milestone);
                    updatedAny = true;
                }
                
                List<TaskDraft> tasks = taskDraftRepository.findByDrftMId(milestone.getDrftMId());
                for (TaskDraft task : tasks) {
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
            if (updatedAny) {
                milestones = milestoneDraftRepository.findByDrftPrjId(prjId);
            }
        }
        return milestones;
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody MilestoneDraft milestone) {
        if (milestone.getMlstnCd() != null && !milestone.getMlstnCd().trim().isEmpty()) {
            if (milestoneDraftRepository.existsByMlstnCd(milestone.getMlstnCd())) {
                return ResponseEntity.badRequest().body(Map.of("message", "Milestone code already exists."));
            }
        }

        ProjectDraft project = projectDraftRepository.findById(milestone.getDrftPrjId())
                .orElseThrow(() -> new RuntimeException("Project not found with ID: " + milestone.getDrftPrjId()));

        milestone.setMlstnSts("DRAFT");
        if (milestone.getSts() == null) {
            milestone.setSts(true);
        }

        // Auto-compute dates or days
        if (milestone.getTentStDt() != null && milestone.getMlstnDays() != null) {
            milestone.setTentEndDt(milestone.getTentStDt().plusDays(milestone.getMlstnDays()));
        } else if (milestone.getTentStDt() != null && milestone.getTentEndDt() != null) {
            long days = java.time.temporal.ChronoUnit.DAYS.between(milestone.getTentStDt(), milestone.getTentEndDt());
            milestone.setMlstnDays((int) days);
        }

        MilestoneDraft saved = milestoneDraftRepository.save(milestone);

        // Validate limits
        String warning = null;
        if (saved.getTentStDt() != null && saved.getTentEndDt() != null) {
            if (saved.getTentStDt().isBefore(project.getTentStDt()) ||
                saved.getTentEndDt().isAfter(project.getTentEndDt()) ||
                (saved.getMlstnDays() != null && project.getNoOfDays() != null && saved.getMlstnDays() > project.getNoOfDays())) {
                warning = "Warning: Milestone dates/days exceed project limits. You must also update the Project dates/days accordingly.";
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("data", saved);
        if (warning != null) {
            response.put("warning", warning);
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody MilestoneDraft details) {
        MilestoneDraft milestone = milestoneDraftRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Milestone not found: " + id));

        if (details.getMlstnCd() != null && !details.getMlstnCd().trim().isEmpty()) {
            if (milestoneDraftRepository.existsByMlstnCdAndDrftMIdNot(details.getMlstnCd(), id)) {
                return ResponseEntity.badRequest().body(Map.of("message", "Milestone code already exists."));
            }
            milestone.setMlstnCd(details.getMlstnCd());
        }

        milestone.setDrftPrjId(details.getDrftPrjId());
        milestone.setMlstnTtl(details.getMlstnTtl());
        milestone.setMlstnDesc(details.getMlstnDesc());
        milestone.setMlstnDepFlg(details.getMlstnDepFlg());
        milestone.setMlstnDepTyp(details.getMlstnDepTyp());
        milestone.setMlstnDepMId(details.getMlstnDepMId());

        // Auto-compute dates or days based on changes
        if (details.getTentStDt() != null && details.getMlstnDays() != null) {
            milestone.setTentStDt(details.getTentStDt());
            milestone.setMlstnDays(details.getMlstnDays());
            milestone.setTentEndDt(details.getTentStDt().plusDays(details.getMlstnDays()));
        } else if (details.getTentStDt() != null && details.getTentEndDt() != null) {
            milestone.setTentStDt(details.getTentStDt());
            milestone.setTentEndDt(details.getTentEndDt());
            long days = java.time.temporal.ChronoUnit.DAYS.between(details.getTentStDt(), details.getTentEndDt());
            milestone.setMlstnDays((int) days);
        } else {
            milestone.setMlstnDays(details.getMlstnDays());
            milestone.setTentStDt(details.getTentStDt());
            milestone.setTentEndDt(details.getTentEndDt());
        }

        milestone.setChkId(details.getChkId());
        milestone.setFileUrl(details.getFileUrl());
        milestone.setAddlRem(details.getAddlRem());
        milestone.setSts(details.getSts());

        MilestoneDraft saved = milestoneDraftRepository.save(milestone);

        ProjectDraft project = projectDraftRepository.findById(saved.getDrftPrjId())
                .orElseThrow(() -> new RuntimeException("Project not found with ID: " + saved.getDrftPrjId()));

        String warning = null;
        if (saved.getTentStDt() != null && saved.getTentEndDt() != null) {
            if (saved.getTentStDt().isBefore(project.getTentStDt()) ||
                saved.getTentEndDt().isAfter(project.getTentEndDt()) ||
                (saved.getMlstnDays() != null && project.getNoOfDays() != null && saved.getMlstnDays() > project.getNoOfDays())) {
                warning = "Warning: Milestone dates/days exceed project limits. You must also update the Project dates/days accordingly.";
            }
        }

        // Also check if any existing Tasks of this milestone now exceed the updated milestone's dates/days
        if (warning == null) {
            List<TaskDraft> tasks = taskDraftRepository.findByDrftMId(id);
            for (TaskDraft task : tasks) {
                if (task.getTentStDt().isBefore(saved.getTentStDt()) ||
                    task.getTentEndDt().isAfter(saved.getTentEndDt()) ||
                    (task.getNoOfDays() != null && saved.getMlstnDays() != null && task.getNoOfDays() > saved.getMlstnDays())) {
                    warning = "Warning: Some tasks now exceed the updated milestone limits. Please review and update them accordingly.";
                    break;
                }
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("data", saved);
        if (warning != null) {
            response.put("warning", warning);
        }
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        List<TaskDraft> tasks = taskDraftRepository.findByDrftMId(id);
        for (TaskDraft task : tasks) {
            List<com.bionova.entity.ChecklistMaster> checklists = checklistMasterRepository.findByTaskIdAndIsLive(task.getDrftTaskId(), false);
            checklistMasterRepository.deleteAll(checklists);

            List<com.bionova.entity.AttachmentMaster> attachments = attachmentMasterRepository.findByTIdAndIsLive(task.getDrftTaskId(), false);
            attachmentMasterRepository.deleteAll(attachments);

            List<com.bionova.entity.ProcessConfig> processConfigs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(task.getDrftTaskId(), false);
            processConfigRepository.deleteAll(processConfigs);

            taskDraftRepository.delete(task);
        }
        milestoneDraftRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
