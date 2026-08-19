package com.bionova.service;

import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.entity.TaskStatusMaster;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;

import java.util.List;

@Service
public class ProjectStatusCascadeService {

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private ProjectLeadLagService projectLeadLagService;

    @Autowired
    private com.bionova.repository.ChecklistMasterRepository checklistMasterRepository;

    public void reopenChecklistsForTask(Long taskId) {
        if (taskId == null) return;
        List<com.bionova.entity.ChecklistMaster> liveChecklists = checklistMasterRepository.findByTaskId(taskId);
        if (liveChecklists != null && !liveChecklists.isEmpty()) {
            for (com.bionova.entity.ChecklistMaster chk : liveChecklists) {
                chk.setChkSts(false);
            }
            checklistMasterRepository.saveAll(liveChecklists);
        }
    }

    public boolean isTaskPrerequisitesMet(TaskLive task) {
        if (task == null) return false;

        // 1. Check task-level sequential dependency
        if (Boolean.TRUE.equals(task.getTaskDepFlg()) && "SEQUENTIAL".equalsIgnoreCase(task.getTaskDepTyp()) && task.getDepTaskId() != null) {
            TaskLive pred = taskLiveRepository.findById(task.getDepTaskId()).orElse(null);
            if (pred != null) {
                String pSts = pred.getTaskSts() != null ? pred.getTaskSts().getStatusNm() : "";
                if (!"Closed".equalsIgnoreCase(pSts) && !"Completed".equalsIgnoreCase(pSts)) {
                    return false;
                }
            }
        }

        // 2. Check milestone-level sequential dependency
        if (task.getMId() != null) {
            MilestoneLive ms = milestoneLiveRepository.findById(task.getMId()).orElse(null);
            if (ms != null && Boolean.TRUE.equals(ms.getMlstnDepFlg()) && "SEQUENTIAL".equalsIgnoreCase(ms.getMlstnDepTyp()) && ms.getMlstnDepMId() != null) {
                MilestoneLive predMs = milestoneLiveRepository.findById(ms.getMlstnDepMId()).orElse(null);
                if (predMs != null && !"CLOSED".equalsIgnoreCase(predMs.getMlstnSts())) {
                    return false;
                }
            }
        }

        return true;
    }

    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void syncAllStatusesOnStartup() {
        try {
            List<MilestoneLive> allMilestones = milestoneLiveRepository.findAll();
            for (MilestoneLive ms : allMilestones) {
                List<TaskLive> milestoneTasks = taskLiveRepository.findByMilestoneId(ms.getMId());
                if (!milestoneTasks.isEmpty()) {
                    boolean allClosed = true;
                    for (TaskLive t : milestoneTasks) {
                        String sts = t.getTaskSts() != null ? t.getTaskSts().getStatusNm() : "";
                        if (!"Closed".equalsIgnoreCase(sts) && !"Completed".equalsIgnoreCase(sts)) {
                            allClosed = false;
                            break;
                        }
                    }
                    if (allClosed && !"CLOSED".equalsIgnoreCase(ms.getMlstnSts())) {
                        ms.setMlstnSts("CLOSED");
                        milestoneLiveRepository.save(ms);
                    }
                }
            }

            List<ProjectLive> allProjects = projectLiveRepository.findAll();
            for (ProjectLive prj : allProjects) {
                List<MilestoneLive> prjMilestones = milestoneLiveRepository.findByPrjId(prj.getPrjId());
                if (!prjMilestones.isEmpty()) {
                    boolean allMsClosed = true;
                    for (MilestoneLive ms : prjMilestones) {
                        if (!"CLOSED".equalsIgnoreCase(ms.getMlstnSts())) {
                            allMsClosed = false;
                            break;
                        }
                    }
                    if (allMsClosed && !"CLOSED".equalsIgnoreCase(prj.getPrjSts())) {
                        prj.setPrjSts("CLOSED");
                        projectLiveRepository.save(prj);
                    }
                }
            }

            // Ensure all live tasks in Draft are set to OPEN so they are visible to employees
            List<TaskLive> allTasks = taskLiveRepository.findAll();
            for (TaskLive t : allTasks) {
                String sts = t.getTaskSts() != null ? t.getTaskSts().getStatusNm() : "";
                if ("Draft".equalsIgnoreCase(sts)) {
                    t.setTaskSts(TaskStatusMaster.OPEN);
                    taskLiveRepository.save(t);
                }
            }
        } catch (Exception e) {
            // Log warning gracefully
        }
    }

    @Transactional(propagation = Propagation.REQUIRED)
    public void cascadeStatusFromTask(Long taskId) {
        TaskLive task = taskLiveRepository.findById(taskId).orElse(null);
        if (task == null) return;

        // Release downstream sequential tasks if this task is completed
        if (task.getTaskSts() != null && ("Closed".equalsIgnoreCase(task.getTaskSts().getStatusNm()) || "Completed".equalsIgnoreCase(task.getTaskSts().getStatusNm()))) {
            List<TaskLive> downstreamTasks = taskLiveRepository.findByDepTaskId(taskId);
            for (TaskLive dt : downstreamTasks) {
                String dtSts = dt.getTaskSts() != null ? dt.getTaskSts().getStatusNm() : "";
                if ("Draft".equalsIgnoreCase(dtSts) || "".equalsIgnoreCase(dtSts) || "Hold".equalsIgnoreCase(dtSts)) {
                    if (isTaskPrerequisitesMet(dt)) {
                        dt.setTaskSts(TaskStatusMaster.OPEN);
                        taskLiveRepository.save(dt);
                    }
                }
            }
        }

        Long milestoneId = task.getMId();
        if (milestoneId == null) return;

        MilestoneLive milestone = milestoneLiveRepository.findById(milestoneId).orElse(null);
        if (milestone == null) return;

        // 1. Fetch all tasks under this milestone to compute milestone status
        List<TaskLive> milestoneTasks = taskLiveRepository.findByMilestoneId(milestoneId);
        boolean allCompleted = !milestoneTasks.isEmpty();
        boolean anyStarted = false;

        for (TaskLive t : milestoneTasks) {
            String sts = t.getTaskSts() != null ? t.getTaskSts().getStatusNm() : "Open";
            if (!"Closed".equalsIgnoreCase(sts) && !"Completed".equalsIgnoreCase(sts)) {
                allCompleted = false;
            }
            if ("WIP".equalsIgnoreCase(sts) || "Closed".equalsIgnoreCase(sts) || "Completed".equalsIgnoreCase(sts)) {
                anyStarted = true;
            }
        }

        String currentMilestoneStatus = milestone.getMlstnSts() != null ? milestone.getMlstnSts() : "LIVE";
        String targetMilestoneStatus = currentMilestoneStatus;

        if (allCompleted) {
            targetMilestoneStatus = "CLOSED";
        } else if (anyStarted) {
            if ("CLOSED".equals(currentMilestoneStatus)) {
                targetMilestoneStatus = "LIVE";
            }
        }

        if (!targetMilestoneStatus.equals(currentMilestoneStatus)) {
            milestone.setMlstnSts(targetMilestoneStatus);
            milestoneLiveRepository.save(milestone);

            // If milestone became CLOSED, release any downstream sequential milestones
            if ("CLOSED".equals(targetMilestoneStatus)) {
                List<MilestoneLive> downstreamMilestones = milestoneLiveRepository.findByMlstnDepMId(milestoneId);
                for (MilestoneLive dms : downstreamMilestones) {
                    List<TaskLive> dmsTasks = taskLiveRepository.findByMilestoneId(dms.getMId());
                    for (TaskLive dmt : dmsTasks) {
                        String dmtSts = dmt.getTaskSts() != null ? dmt.getTaskSts().getStatusNm() : "";
                        if ("Draft".equalsIgnoreCase(dmtSts) || "Hold".equalsIgnoreCase(dmtSts) || "".equalsIgnoreCase(dmtSts)) {
                            if (isTaskPrerequisitesMet(dmt)) {
                                dmt.setTaskSts(TaskStatusMaster.OPEN);
                                taskLiveRepository.save(dmt);
                            }
                        }
                    }
                }
            }
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
            if (!"CLOSED".equals(msSts)) {
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

        // Recalculate Lead/Lag/OnTime status for this project
        projectLeadLagService.recalculateAndPersist(projectId);
    }

    /**
     * Recursively cascades the REWORK status to all downstream tasks that depend on the given task.
     * This ensures that if a task is rejected, any tasks relying on its completion are also reset.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public void cascadeReworkDownstream(Long taskId) {
        List<TaskLive> downstreamTasks = taskLiveRepository.findByDepTaskId(taskId);
        for (TaskLive dt : downstreamTasks) {
            String sts = dt.getTaskSts() != null ? dt.getTaskSts().getStatusNm() : "Open";
            if (!"Open".equalsIgnoreCase(sts)) {
                dt.setTaskSts(TaskStatusMaster.OPEN);
                taskLiveRepository.save(dt);
                
                // Recursively cascade status change downstream
                cascadeReworkDownstream(dt.getTaskId());
                
                // Recalculate status of the milestone and project containing the downstream task
                cascadeStatusFromTask(dt.getTaskId());
            }
        }
    }

    /**
     * Routes a REWORK request from a current milestone/task back to the target previous milestone's task executor.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public TaskLive routeReworkToPreviousMilestoneTask(Long currentTaskId, Long targetMId) {
        return routeReworkToPreviousMilestoneTask(currentTaskId, targetMId, null);
    }

    @Transactional(propagation = Propagation.REQUIRED)
    public TaskLive routeReworkToPreviousMilestoneTask(Long currentTaskId, Long targetMId, Long targetTaskId) {
        TaskLive currentTask = taskLiveRepository.findById(currentTaskId).orElse(null);
        if (currentTask == null) return null;

        TaskLive targetTask = null;

        // 0. If targetTaskId is explicitly provided, verify it exists
        if (targetTaskId != null && !targetTaskId.equals(currentTaskId)) {
            TaskLive directTask = taskLiveRepository.findById(targetTaskId).orElse(null);
            if (directTask != null) {
                targetTask = directTask;
            }
        }

        // 1. If targetMId is explicitly provided and DIFFERENT from current milestone, find task in that specified milestone
        if (targetTask == null && targetMId != null && !targetMId.equals(currentTask.getMId())) {
            List<TaskLive> targetMTasks = taskLiveRepository.findByMilestoneId(targetMId);
            if (!targetMTasks.isEmpty()) {
                targetTask = targetMTasks.stream()
                        .min((t1, t2) -> {
                            if (t1.getStDt() != null && t2.getStDt() != null) {
                                int cmp = t1.getStDt().compareTo(t2.getStDt());
                                if (cmp != 0) return cmp;
                            }
                            return Long.compare(t1.getTaskId(), t2.getTaskId());
                        })
                        .orElse(targetMTasks.get(0));
            }
        }

        // 2. If targetTask is still null, check depTaskId
        if (targetTask == null && currentTask.getDepTaskId() != null) {
            TaskLive depTask = taskLiveRepository.findById(currentTask.getDepTaskId()).orElse(null);
            if (depTask != null && !depTask.getTaskId().equals(currentTaskId)) {
                targetTask = depTask;
            }
        }

        // 3. Preceding task in same milestone
        if (targetTask == null && currentTask.getMId() != null) {
            List<TaskLive> sameMTasks = taskLiveRepository.findByMilestoneId(currentTask.getMId());
            if (sameMTasks.size() > 1) {
                targetTask = sameMTasks.stream()
                        .filter(t -> !t.getTaskId().equals(currentTaskId) && t.getTaskId() < currentTaskId)
                        .max((t1, t2) -> Long.compare(t1.getTaskId(), t2.getTaskId()))
                        .orElse(null);
            }
        }

        // 4. Previous milestone task
        if (targetTask == null && currentTask.getMId() != null) {
            MilestoneLive currentM = milestoneLiveRepository.findById(currentTask.getMId()).orElse(null);
            if (currentM != null && currentM.getPrjId() != null) {
                List<MilestoneLive> allMilestones = new java.util.ArrayList<>(milestoneLiveRepository.findByPrjId(currentM.getPrjId()));
                allMilestones.sort((m1, m2) -> {
                    if (m1.getMlstnCd() != null && m2.getMlstnCd() != null) {
                        int cmp = m1.getMlstnCd().compareToIgnoreCase(m2.getMlstnCd());
                        if (cmp != 0) return cmp;
                    }
                    return Long.compare(m1.getMId(), m2.getMId());
                });
                int currIdx = -1;
                for (int i = 0; i < allMilestones.size(); i++) {
                    if (allMilestones.get(i).getMId().equals(currentM.getMId())) {
                        currIdx = i;
                        break;
                    }
                }
                if (currIdx > 0) {
                    MilestoneLive prevM = allMilestones.get(currIdx - 1);
                    List<TaskLive> prevMTasks = taskLiveRepository.findByMilestoneId(prevM.getMId());
                    if (!prevMTasks.isEmpty()) {
                        targetTask = prevMTasks.get(0);
                    }
                }
            }
        }

        // Fallback: If no target task found, rework current task
        if (targetTask == null) {
            targetTask = currentTask;
        }

        Long prjId = currentTask.getPrjId();
        if (prjId == null && currentTask.getMId() != null) {
            MilestoneLive cm = milestoneLiveRepository.findById(currentTask.getMId()).orElse(null);
            if (cm != null) prjId = cm.getPrjId();
        }
        if (prjId == null && targetTask.getMId() != null) {
            MilestoneLive tm = milestoneLiveRepository.findById(targetTask.getMId()).orElse(null);
            if (tm != null) prjId = tm.getPrjId();
        }

        if (prjId != null) {
            List<MilestoneLive> allMilestones = new java.util.ArrayList<>(milestoneLiveRepository.findByPrjId(prjId));
            allMilestones.sort((m1, m2) -> {
                if (m1.getMlstnCd() != null && m2.getMlstnCd() != null) {
                    int cmp = m1.getMlstnCd().compareToIgnoreCase(m2.getMlstnCd());
                    if (cmp != 0) return cmp;
                }
                if (m1.getStDt() != null && m2.getStDt() != null) {
                    int cmp = m1.getStDt().compareTo(m2.getStDt());
                    if (cmp != 0) return cmp;
                }
                return Long.compare(m1.getMId(), m2.getMId());
            });

            Long targetMIdVal = targetTask.getMId();
            int targetMIdx = -1;
            for (int i = 0; i < allMilestones.size(); i++) {
                if (allMilestones.get(i).getMId().equals(targetMIdVal)) {
                    targetMIdx = i;
                    break;
                }
            }

            if (targetMIdx >= 0) {
                // Iterate through all milestones from target milestone onwards
                for (int i = targetMIdx; i < allMilestones.size(); i++) {
                    MilestoneLive ms = allMilestones.get(i);
                    // Reopen milestone to LIVE if it was CLOSED/COMPLETED
                    if (!"LIVE".equalsIgnoreCase(ms.getMlstnSts())) {
                        ms.setMlstnSts("LIVE");
                        milestoneLiveRepository.save(ms);
                    }

                    List<TaskLive> mTasks = new java.util.ArrayList<>(taskLiveRepository.findByMilestoneId(ms.getMId()));
                    mTasks.sort((t1, t2) -> {
                        if (t1.getTaskCd() != null && t2.getTaskCd() != null) {
                            int cmp = t1.getTaskCd().compareToIgnoreCase(t2.getTaskCd());
                            if (cmp != 0) return cmp;
                        }
                        if (t1.getStDt() != null && t2.getStDt() != null) {
                            int cmp = t1.getStDt().compareTo(t2.getStDt());
                            if (cmp != 0) return cmp;
                        }
                        return Long.compare(t1.getTaskId(), t2.getTaskId());
                    });

                    if (i == targetMIdx) {
                        int targetTaskIdx = -1;
                        for (int tIdx = 0; tIdx < mTasks.size(); tIdx++) {
                            if (mTasks.get(tIdx).getTaskId().equals(targetTask.getTaskId())) {
                                targetTaskIdx = tIdx;
                                break;
                            }
                        }

                        // For target task: Set to WIP (Rework), clear completion date, and reset checklists (0% progress)
                        targetTask.setTaskSts(TaskStatusMaster.WIP);
                        targetTask.setSubStatus("Rework");
                        targetTask.setPrcsYesActn("REWORK");
                        targetTask.setActCmpDt(null);
                        reopenChecklistsForTask(targetTask.getTaskId());
                        taskLiveRepository.save(targetTask);

                        // For tasks AFTER targetTask in targetMilestone: Reset to OPEN, prcsYesActn NONE, clear completion date, reset checklists
                        if (targetTaskIdx >= 0) {
                            for (int tIdx = targetTaskIdx + 1; tIdx < mTasks.size(); tIdx++) {
                                TaskLive subsequentTask = mTasks.get(tIdx);
                                subsequentTask.setTaskSts(TaskStatusMaster.OPEN);
                                subsequentTask.setSubStatus(null);
                                subsequentTask.setPrcsYesActn("NONE");
                                subsequentTask.setActCmpDt(null);
                                reopenChecklistsForTask(subsequentTask.getTaskId());
                                taskLiveRepository.save(subsequentTask);
                            }
                        }
                    } else {
                        // For subsequent milestones (e.g. MLS-002, MLS-003): Reset ALL tasks to OPEN, prcsYesActn NONE, clear completion date, reset checklists
                        for (TaskLive t : mTasks) {
                            t.setTaskSts(TaskStatusMaster.OPEN);
                            t.setSubStatus(null);
                            t.setPrcsYesActn("NONE");
                            t.setActCmpDt(null);
                            reopenChecklistsForTask(t.getTaskId());
                            taskLiveRepository.save(t);
                        }
                    }
                }
            }
        } else {
            // Standalone or non-project task fallback
            targetTask.setTaskSts(TaskStatusMaster.WIP);
            targetTask.setSubStatus("Rework");
            targetTask.setPrcsYesActn("REWORK");
            targetTask.setActCmpDt(null);
            reopenChecklistsForTask(targetTask.getTaskId());
            taskLiveRepository.save(targetTask);

            if (!targetTask.getTaskId().equals(currentTaskId)) {
                currentTask.setTaskSts(TaskStatusMaster.OPEN);
                currentTask.setSubStatus(null);
                currentTask.setPrcsYesActn("NONE");
                currentTask.setActCmpDt(null);
                reopenChecklistsForTask(currentTaskId);
                taskLiveRepository.save(currentTask);
            }
        }

        cascadeReworkDownstream(targetTask.getTaskId());
        cascadeReworkDownstream(currentTaskId);
        cascadeStatusFromTask(targetTask.getTaskId());
        cascadeStatusFromTask(currentTaskId);
        return targetTask;
    }

    /**
     * Cascades project status updates (LIVE, HOLD, CLOSED) down to all milestones and tasks of the project.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public void cascadeStatusFromProject(Long projectId, String newProjectStatus) {
        ProjectLive project = projectLiveRepository.findById(projectId).orElse(null);
        if (project == null) return;

        List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(projectId);
        
        String milestoneStatus = null;
        TaskStatusMaster taskStatus = null;
        
        if ("HOLD".equalsIgnoreCase(newProjectStatus)) {
            milestoneStatus = "HOLD";
            taskStatus = TaskStatusMaster.HOLD;
        } else if ("CLOSED".equalsIgnoreCase(newProjectStatus)) {
            milestoneStatus = "CLOSED";
            taskStatus = TaskStatusMaster.CLOSED;
        } else if ("LIVE".equalsIgnoreCase(newProjectStatus)) {
            milestoneStatus = "LIVE";
            taskStatus = TaskStatusMaster.OPEN;
        }

        if (milestoneStatus == null) return;

        for (MilestoneLive ms : milestones) {
            if ("HOLD".equals(milestoneStatus)) {
                if (!"CLOSED".equalsIgnoreCase(ms.getMlstnSts())) {
                    ms.setMlstnSts("HOLD");
                    milestoneLiveRepository.save(ms);
                }
            } else if ("CLOSED".equals(milestoneStatus)) {
                ms.setMlstnSts("CLOSED");
                milestoneLiveRepository.save(ms);
            } else if ("LIVE".equals(milestoneStatus)) {
                if ("HOLD".equalsIgnoreCase(ms.getMlstnSts())) {
                    ms.setMlstnSts("LIVE");
                    milestoneLiveRepository.save(ms);
                }
            }

            List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(ms.getMId());
            for (TaskLive t : tasks) {
                if (taskStatus == TaskStatusMaster.HOLD) {
                    String sts = t.getTaskSts() != null ? t.getTaskSts().getStatusNm() : "";
                    if (!"Closed".equalsIgnoreCase(sts)) {
                        t.setTaskSts(TaskStatusMaster.HOLD);
                        taskLiveRepository.save(t);
                    }
                } else if (taskStatus == TaskStatusMaster.CLOSED) {
                    t.setTaskSts(TaskStatusMaster.CLOSED);
                    if (t.getActCmpDt() == null) {
                        t.setActCmpDt(java.time.LocalDate.now());
                    }
                    taskLiveRepository.save(t);
                } else if (taskStatus == TaskStatusMaster.OPEN) {
                    if (t.getTaskSts() != null && "Hold".equalsIgnoreCase(t.getTaskSts().getStatusNm())) {
                        t.setTaskSts(TaskStatusMaster.OPEN);
                        taskLiveRepository.save(t);
                    }
                }
            }
        }
        
        projectLeadLagService.recalculateAndPersist(projectId);
    }
}
