package com.bionova.service;

import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ProjectStatusCascadeService {

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Transactional
    public void cascadeStatusFromTask(Long taskId) {
        TaskLive task = taskLiveRepository.findById(taskId).orElse(null);
        if (task == null) return;

        Long milestoneId = task.getMId();
        if (milestoneId == null) return;

        MilestoneLive milestone = milestoneLiveRepository.findById(milestoneId).orElse(null);
        if (milestone == null) return;

        // 1. Fetch all tasks under this milestone to compute milestone status
        List<TaskLive> milestoneTasks = taskLiveRepository.findByMilestoneId(milestoneId);
        boolean allCompleted = !milestoneTasks.isEmpty();
        boolean anyStarted = false;

        for (TaskLive t : milestoneTasks) {
            String sts = t.getTaskSts() != null ? t.getTaskSts() : "OPEN";
            if (!"COMPLETED".equals(sts)) {
                allCompleted = false;
            }
            if ("WIP".equals(sts) || "SUBMIT_REVIEW".equals(sts) || "UNDER_REVIEW".equals(sts) || "COMPLETED".equals(sts)) {
                anyStarted = true;
            }
        }

        String currentMilestoneStatus = milestone.getMlstnSts() != null ? milestone.getMlstnSts() : "LIVE";
        String targetMilestoneStatus = currentMilestoneStatus;

        if (allCompleted) {
            targetMilestoneStatus = "COMPLETED";
        } else if (anyStarted) {
            if ("COMPLETED".equals(currentMilestoneStatus) || "CLOSED".equals(currentMilestoneStatus)) {
                targetMilestoneStatus = "LIVE";
            }
        }

        if (!targetMilestoneStatus.equals(currentMilestoneStatus)) {
            milestone.setMlstnSts(targetMilestoneStatus);
            milestoneLiveRepository.save(milestone);
        }

        // 2. Fetch all milestones under this project to compute project status
        Long projectId = milestone.getPrjId();
        if (projectId == null) return;

        ProjectLive project = projectLiveRepository.findById(projectId).orElse(null);
        if (project == null) return;

        List<MilestoneLive> projectMilestones = milestoneLiveRepository.findByPrjId(projectId);
        boolean allMilestonesCompleted = !projectMilestones.isEmpty();

        for (MilestoneLive ms : projectMilestones) {
            String msSts = ms.getMlstnSts() != null ? ms.getMlstnSts() : "LIVE";
            if (!"COMPLETED".equals(msSts)) {
                allMilestonesCompleted = false;
                break;
            }
        }

        String currentProjectStatus = project.getPrjSts() != null ? project.getPrjSts() : "LIVE";
        String targetProjectStatus = currentProjectStatus;

        if (allMilestonesCompleted) {
            targetProjectStatus = "CLOSED";
        } else {
            if ("CLOSED".equals(currentProjectStatus)) {
                targetProjectStatus = "LIVE";
            }
        }

        if (!targetProjectStatus.equals(currentProjectStatus)) {
            project.setPrjSts(targetProjectStatus);
            projectLiveRepository.save(project);
        }
    }
}
