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
@RequestMapping("/api/task-drafts")
public class TaskDraftController {

    @Autowired
    private TaskDraftRepository taskDraftRepository;

    @Autowired
    private MilestoneDraftRepository milestoneDraftRepository;

    @Autowired
    private ProjectDraftRepository projectDraftRepository;

    @GetMapping
    public List<TaskDraft> getAll() {
        return taskDraftRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskDraft> getById(@PathVariable Long id) {
        return taskDraftRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-milestone/{mId}")
    public List<TaskDraft> getByMilestone(@PathVariable Long mId) {
        return taskDraftRepository.findByDrftMId(mId);
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody TaskDraft task) {
        if (task.getTaskCd() != null && !task.getTaskCd().trim().isEmpty()) {
            if (taskDraftRepository.existsByTaskCd(task.getTaskCd())) {
                return ResponseEntity.badRequest().body(Map.of("message", "Task code already exists."));
            }
        }

        MilestoneDraft milestone = milestoneDraftRepository.findById(task.getDrftMId())
                .orElseThrow(() -> new RuntimeException("Milestone not found with ID: " + task.getDrftMId()));

        task.setTaskSts("DRAFT");
        if (task.getSts() == null) {
            task.setSts(true);
        }

        // Auto-compute dates or days
        if (task.getTentStDt() != null && task.getNoOfDays() != null) {
            task.setTentEndDt(task.getTentStDt().plusDays(task.getNoOfDays()));
        } else if (task.getTentStDt() != null && task.getTentEndDt() != null) {
            long days = java.time.temporal.ChronoUnit.DAYS.between(task.getTentStDt(), task.getTentEndDt());
            task.setNoOfDays((int) days);
        }

        TaskDraft saved = taskDraftRepository.save(task);

        // Validate limits (Milestone & Project)
        String warning = null;
        if (saved.getTentStDt() != null && saved.getTentEndDt() != null) {
            boolean exceedsMilestone = saved.getTentStDt().isBefore(milestone.getTentStDt()) ||
                                       saved.getTentEndDt().isAfter(milestone.getTentEndDt()) ||
                                       (saved.getNoOfDays() != null && milestone.getMlstnDays() != null && saved.getNoOfDays() > milestone.getMlstnDays());
            
            boolean exceedsProject = false;
            ProjectDraft project = projectDraftRepository.findById(milestone.getDrftPrjId()).orElse(null);
            if (project != null) {
                exceedsProject = saved.getTentStDt().isBefore(project.getTentStDt()) ||
                                 saved.getTentEndDt().isAfter(project.getTentEndDt()) ||
                                 (saved.getNoOfDays() != null && project.getNoOfDays() != null && saved.getNoOfDays() > project.getNoOfDays());
            }

            if (exceedsMilestone || exceedsProject) {
                warning = "Warning: Task dates/days exceed milestone limits. You must also update the Milestone and Project dates/days accordingly.";
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
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody TaskDraft details) {
        TaskDraft task = taskDraftRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found: " + id));

        if (details.getTaskCd() != null && !details.getTaskCd().trim().isEmpty()) {
            if (taskDraftRepository.existsByTaskCdAndDrftTaskIdNot(details.getTaskCd(), id)) {
                return ResponseEntity.badRequest().body(Map.of("message", "Task code already exists."));
            }
            task.setTaskCd(details.getTaskCd());
        }

        task.setDrftMId(details.getDrftMId());
        task.setTaskNm(details.getTaskNm());
        task.setTaskDesc(details.getTaskDesc());
        task.setTaskTyp(details.getTaskTyp());
        task.setEmpId(details.getEmpId());
        task.setExtEmpId(details.getExtEmpId());
        task.setTaskDepFlg(details.getTaskDepFlg());
        task.setTaskDepTyp(details.getTaskDepTyp());
        task.setDepTaskId(details.getDepTaskId());
        
        // Auto-compute dates or days based on changes
        if (details.getTentStDt() != null && details.getNoOfDays() != null) {
            task.setTentStDt(details.getTentStDt());
            task.setNoOfDays(details.getNoOfDays());
            task.setTentEndDt(details.getTentStDt().plusDays(details.getNoOfDays()));
        } else if (details.getTentStDt() != null && details.getTentEndDt() != null) {
            task.setTentStDt(details.getTentStDt());
            task.setTentEndDt(details.getTentEndDt());
            long days = java.time.temporal.ChronoUnit.DAYS.between(details.getTentStDt(), details.getTentEndDt());
            task.setNoOfDays((int) days);
        } else {
            task.setNoOfDays(details.getNoOfDays());
            task.setTentStDt(details.getTentStDt());
            task.setTentEndDt(details.getTentEndDt());
        }

        task.setChkFlg(details.getChkFlg());
        task.setChkId(details.getChkId());
        task.setFilePath(details.getFilePath());
        task.setNoteTxt(details.getNoteTxt());
        task.setPrcsFlg(details.getPrcsFlg());
        task.setPrcsYesActn(details.getPrcsYesActn());
        task.setAddlRem(details.getAddlRem());
        task.setSts(details.getSts());

        TaskDraft saved = taskDraftRepository.save(task);

        MilestoneDraft milestone = milestoneDraftRepository.findById(saved.getDrftMId())
                .orElseThrow(() -> new RuntimeException("Milestone not found with ID: " + saved.getDrftMId()));

        // Validate limits (Milestone & Project)
        String warning = null;
        if (saved.getTentStDt() != null && saved.getTentEndDt() != null) {
            boolean exceedsMilestone = saved.getTentStDt().isBefore(milestone.getTentStDt()) ||
                                       saved.getTentEndDt().isAfter(milestone.getTentEndDt()) ||
                                       (saved.getNoOfDays() != null && milestone.getMlstnDays() != null && saved.getNoOfDays() > milestone.getMlstnDays());
            
            boolean exceedsProject = false;
            ProjectDraft project = projectDraftRepository.findById(milestone.getDrftPrjId()).orElse(null);
            if (project != null) {
                exceedsProject = saved.getTentStDt().isBefore(project.getTentStDt()) ||
                                 saved.getTentEndDt().isAfter(project.getTentEndDt()) ||
                                 (saved.getNoOfDays() != null && project.getNoOfDays() != null && saved.getNoOfDays() > project.getNoOfDays());
            }

            if (exceedsMilestone || exceedsProject) {
                warning = "Warning: Task dates/days exceed milestone limits. You must also update the Milestone and Project dates/days accordingly.";
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
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        taskDraftRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
