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

    @Transactional(propagation = Propagation.REQUIRED)
    public void cascadeStatusFromTask(Long taskId) {
        TaskLive task = taskLiveRepository.findById(taskId).orElse(null);
        if (task == null) return;

        // Release downstream sequential tasks if this task is completed
        if (task.getTaskSts() != null && "Closed".equalsIgnoreCase(task.getTaskSts().getStatusNm())) {
            List<TaskLive> downstreamTasks = taskLiveRepository.findByDepTaskId(taskId);
            for (TaskLive dt : downstreamTasks) {
                String dtSts = dt.getTaskSts() != null ? dt.getTaskSts().getStatusNm() : "";
                if ("Draft".equalsIgnoreCase(dtSts) || "".equalsIgnoreCase(dtSts)) {
                    dt.setTaskSts(TaskStatusMaster.OPEN);
                    taskLiveRepository.save(dt);
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
            if (!"Closed".equalsIgnoreCase(sts)) {
                allCompleted = false;
            }
            if ("WIP".equalsIgnoreCase(sts) || "Closed".equalsIgnoreCase(sts)) {
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
     * Routes a REWORK request from a current milestone/task back to the target previous milestone's last task executor.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public TaskLive routeReworkToPreviousMilestoneTask(Long currentTaskId, Long targetMId) {
        TaskLive currentTask = taskLiveRepository.findById(currentTaskId).orElse(null);
        if (currentTask == null) return null;

        TaskLive targetTask = null;

        // 1. If targetMId is explicitly provided and DIFFERENT from current milestone, find the last task in that specified milestone
        if (targetMId != null && !targetMId.equals(currentTask.getMId())) {
            List<TaskLive> targetMTasks = taskLiveRepository.findByMilestoneId(targetMId);
            if (!targetMTasks.isEmpty()) {
                targetTask = targetMTasks.stream()
                        .max((t1, t2) -> {
                            if (t1.getEndDt() != null && t2.getEndDt() != null) {
                                int cmp = t1.getEndDt().compareTo(t2.getEndDt());
                                if (cmp != 0) return cmp;
                            }
                            return Long.compare(t1.getTaskId(), t2.getTaskId());
                        })
                        .orElse(null);
            }
        }

        // 2. If targetTask is still null, check depTaskId (if depTaskId points to a task other than currentTaskId)
        if (targetTask == null && currentTask.getDepTaskId() != null) {
            TaskLive depTask = taskLiveRepository.findById(currentTask.getDepTaskId()).orElse(null);
            if (depTask != null && !depTask.getTaskId().equals(currentTaskId)) {
                targetTask = depTask;
            }
        }

        // 3. If targetTask is still null, check if there is a preceding task in the same milestone
        if (targetTask == null && currentTask.getMId() != null) {
            List<TaskLive> sameMTasks = taskLiveRepository.findByMilestoneId(currentTask.getMId());
            if (sameMTasks.size() > 1) {
                targetTask = sameMTasks.stream()
                        .filter(t -> !t.getTaskId().equals(currentTaskId) && t.getTaskId() < currentTaskId)
                        .max((t1, t2) -> {
                            if (t1.getEndDt() != null && t2.getEndDt() != null) {
                                int cmp = t1.getEndDt().compareTo(t2.getEndDt());
                                if (cmp != 0) return cmp;
                            }
                            return Long.compare(t1.getTaskId(), t2.getTaskId());
                        })
                        .orElse(null);
            }
        }

        // 4. If targetTask is still null (e.g. currentTask is Task 1 of current milestone), find previous milestone in the project
        if (targetTask == null && currentTask.getMId() != null) {
            MilestoneLive currentM = milestoneLiveRepository.findById(currentTask.getMId()).orElse(null);
            if (currentM != null && currentM.getPrjId() != null) {
                List<MilestoneLive> allMilestones = milestoneLiveRepository.findByPrjId(currentM.getPrjId());
                allMilestones.sort((m1, m2) -> {
                    if (m1.getStDt() != null && m2.getStDt() != null) {
                        int cmp = m1.getStDt().compareTo(m2.getStDt());
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
                        targetTask = prevMTasks.stream()
                                .max((t1, t2) -> {
                                    if (t1.getEndDt() != null && t2.getEndDt() != null) {
                                        int cmp = t1.getEndDt().compareTo(t2.getEndDt());
                                        if (cmp != 0) return cmp;
                                    }
                                    return Long.compare(t1.getTaskId(), t2.getTaskId());
                                })
                                .orElse(null);
                    }
                }
            }
        }

        // If target task was found, set it to WIP (Rework) and reset current task to OPEN
        if (targetTask != null && !targetTask.getTaskId().equals(currentTaskId)) {
            targetTask.setTaskSts(TaskStatusMaster.WIP);
            targetTask.setSubStatus("Rework");
            targetTask.setPrcsYesActn("REWORK");
            targetTask.setActCmpDt(null);
            taskLiveRepository.save(targetTask);

            // Reopen target milestone to LIVE if it was CLOSED or COMPLETED
            if (targetTask.getMId() != null) {
                milestoneLiveRepository.findById(targetTask.getMId()).ifPresent(m -> {
                    if ("CLOSED".equalsIgnoreCase(m.getMlstnSts()) || "COMPLETED".equalsIgnoreCase(m.getMlstnSts())) {
                        m.setMlstnSts("LIVE");
                        milestoneLiveRepository.save(m);
                    }
                });
            }

            // Reset current task and all tasks in current milestone to OPEN so they wait for previous milestone completion
            currentTask.setTaskSts(TaskStatusMaster.OPEN);
            currentTask.setSubStatus(null);
            currentTask.setActCmpDt(null);
            taskLiveRepository.save(currentTask);

            if (currentTask.getMId() != null) {
                List<TaskLive> currentMTasks = taskLiveRepository.findByMilestoneId(currentTask.getMId());
                for (TaskLive mTask : currentMTasks) {
                    mTask.setTaskSts(TaskStatusMaster.OPEN);
                    mTask.setSubStatus(null);
                    mTask.setActCmpDt(null);
                    taskLiveRepository.save(mTask);
                }
            }

            cascadeReworkDownstream(targetTask.getTaskId());
            cascadeReworkDownstream(currentTaskId);
            cascadeStatusFromTask(targetTask.getTaskId());
            cascadeStatusFromTask(currentTaskId);
            return targetTask;
        } else {
            // Fallback: apply Rework directly to current task if no previous milestone task exists
            currentTask.setTaskSts(TaskStatusMaster.WIP);
            currentTask.setSubStatus("Rework");
            currentTask.setPrcsYesActn("REWORK");
            taskLiveRepository.save(currentTask);
            cascadeReworkDownstream(currentTask.getTaskId());
            cascadeStatusFromTask(currentTask.getTaskId());
            return currentTask;
        }
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
