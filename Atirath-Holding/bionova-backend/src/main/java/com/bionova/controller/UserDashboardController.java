package com.bionova.controller;

import com.bionova.dto.UserDashboardResponseDto;
import com.bionova.dto.UserDashboardResponseDto.*;
import com.bionova.entity.*;
import com.bionova.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/user-dashboard")
public class UserDashboardController {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private PlantRepository plantRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private com.bionova.repository.DesignationRepository designationRepository;

    @GetMapping
    public ResponseEntity<?> getDashboardData() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);

        if (employee == null) {
            return ResponseEntity.notFound().build();
        }

        // 1. Profile Details
        String fullName = employee.getFirstName() + " " + (employee.getLastName() != null ? employee.getLastName() : "");
        String role = getRoleName(employee.getDesigId());
        String department = "Projects Department";
        if (employee.getDeptId() != null) {
            department = departmentRepository.findById(employee.getDeptId().longValue())
                    .map(DepartmentMaster::getDeptNm)
                    .orElse("Projects Department");
        }

        // 2. Fetch User Tasks
        List<TaskLive> allMyTasks = taskLiveRepository.findByEmpId(employee.getEmpId());
        LocalDate today = LocalDate.now();

        // 3. Counts
        int myTasksCount = allMyTasks.size();
        int completedTasksCount = (int) allMyTasks.stream()
                .filter(t -> "COMPLETED".equalsIgnoreCase(t.getTaskSts()))
                .count();

        int overdueTasksCount = (int) allMyTasks.stream()
                .filter(t -> !"COMPLETED".equalsIgnoreCase(t.getTaskSts()) && t.getEndDt() != null && t.getEndDt().isBefore(today))
                .count();

        int dueTodayCount = (int) allMyTasks.stream()
                .filter(t -> !"COMPLETED".equalsIgnoreCase(t.getTaskSts()) && t.getEndDt() != null && t.getEndDt().isEqual(today))
                .count();

        // Fetch User Projects
        List<ProjectLive> myProjectsList = projectLiveRepository.findProjectsByEmpId(employee.getEmpId());
        int myProjectsCount = myProjectsList.size();

        // 4. To-Do List (Pending/Due Today/Overdue tasks, limit 5)
        List<TodoTaskDto> todoList = allMyTasks.stream()
                .filter(t -> !"COMPLETED".equalsIgnoreCase(t.getTaskSts()))
                .filter(t -> t.getStDt() != null && !t.getStDt().isAfter(today))
                .sorted(Comparator.comparing(TaskLive::getEndDt, Comparator.nullsLast(Comparator.naturalOrder())))
                .limit(5)
                .map(t -> {
                    String prjCodeName = "";
                    if (t.getMId() != null) {
                        MilestoneLive ms = milestoneLiveRepository.findById(t.getMId()).orElse(null);
                        if (ms != null) {
                            ProjectLive prj = projectLiveRepository.findById(ms.getPrjId()).orElse(null);
                            if (prj != null) {
                                prjCodeName = prj.getPrjCd() + " • " + ms.getMlstnTtl();
                            }
                        }
                    }
                    boolean isOverdue = t.getEndDt() != null && t.getEndDt().isBefore(today);
                    boolean isDueToday = t.getEndDt() != null && t.getEndDt().isEqual(today);
                    String priority = calculatePriority(t);
                    return new TodoTaskDto(t.getTaskId(), t.getTaskNm(), prjCodeName, priority, t.getEndDt(), isOverdue, isDueToday);
                })
                .collect(Collectors.toList());

        // 5. Upcoming Tasks (Active tasks due in the future, limit 5)
        List<UpcomingTaskDto> upcomingTasks = allMyTasks.stream()
                .filter(t -> !"COMPLETED".equalsIgnoreCase(t.getTaskSts()))
                .filter(t -> t.getStDt() != null && t.getStDt().isAfter(today))
                .sorted(Comparator.comparing(TaskLive::getEndDt))
                .limit(5)
                .map(t -> {
                    String prjCode = "";
                    if (t.getMId() != null) {
                        MilestoneLive ms = milestoneLiveRepository.findById(t.getMId()).orElse(null);
                        if (ms != null) {
                            ProjectLive prj = projectLiveRepository.findById(ms.getPrjId()).orElse(null);
                            if (prj != null) {
                                prjCode = prj.getPrjCd();
                            }
                        }
                    }
                    String priority = calculatePriority(t);
                    return new UpcomingTaskDto(t.getTaskId(), t.getTaskNm(), prjCode, t.getEndDt(), priority);
                })
                .collect(Collectors.toList());

        // 6. User Projects mapping
        List<UserProjectDto> myProjectsDtos = new ArrayList<>();
        for (ProjectLive prj : myProjectsList) {
            String clientName = "Atirath Bio Energy Pvt. Ltd.";
            if (prj.getCoyId() != null) {
                clientName = companyRepository.findById(prj.getCoyId().longValue())
                        .map(CompanyMaster::getCoyNm)
                        .orElse("Atirath Bio Energy Pvt. Ltd.");
            }

            String plantName = "Nalgonda Plant";
            if (prj.getPltId() != null) {
                plantName = plantRepository.findById(prj.getPltId().longValue())
                        .map(PlantMaster::getPltNm)
                        .orElse("Nalgonda Plant");
            }

            // Calculate progress of this project's tasks assigned to this employee
            List<TaskLive> prjTasks = allMyTasks.stream()
                    .filter(t -> {
                        if (t.getMId() == null) return false;
                        return milestoneLiveRepository.findById(t.getMId())
                                .map(ms -> prj.getPrjId().equals(ms.getPrjId()))
                                .orElse(false);
                    })
                    .collect(Collectors.toList());

            int totalPrjTasks = prjTasks.size();
            int completedPrjTasks = (int) prjTasks.stream().filter(t -> "COMPLETED".equalsIgnoreCase(t.getTaskSts())).count();
            double progress = totalPrjTasks > 0 ? Math.round(((double) completedPrjTasks / totalPrjTasks) * 100.0) : 0.0;

            myProjectsDtos.add(new UserProjectDto(
                    prj.getPrjId(),
                    prj.getPrjNm(),
                    prj.getPrjCd(),
                    clientName,
                    plantName,
                    role,
                    progress,
                    totalPrjTasks,
                    totalPrjTasks - completedPrjTasks,
                    "In Progress"
            ));
        }

        // 7. Task Status Distribution (Donut Chart)
        Map<String, Integer> taskStatusCounts = new HashMap<>();
        int wipCount = 0;
        int underReviewCount = 0;
        int pendingCount = 0;
        int overdueCount = 0;

        for (TaskLive t : allMyTasks) {
            if ("COMPLETED".equalsIgnoreCase(t.getTaskSts())) {
                continue; // handled below
            }
            if (t.getEndDt() != null && t.getEndDt().isBefore(today)) {
                overdueCount++;
            } else if ("WIP".equalsIgnoreCase(t.getTaskSts())) {
                wipCount++;
            } else if ("UNDER_REVIEW".equalsIgnoreCase(t.getTaskSts()) || "SUBMIT_REVIEW".equalsIgnoreCase(t.getTaskSts())) {
                underReviewCount++;
            } else {
                pendingCount++;
            }
        }

        taskStatusCounts.put("Completed", completedTasksCount);
        taskStatusCounts.put("In Progress", wipCount);
        taskStatusCounts.put("Under Review", underReviewCount);
        taskStatusCounts.put("Pending", pendingCount);
        taskStatusCounts.put("Overdue", overdueCount);

        double overallCompletionPercentage = myTasksCount > 0 ? Math.round(((double) completedTasksCount / myTasksCount) * 100.0) : 0.0;

        UserDashboardResponseDto response = new UserDashboardResponseDto(
                fullName,
                role,
                department,
                myProjectsCount,
                myTasksCount,
                dueTodayCount,
                overdueTasksCount,
                completedTasksCount,
                todoList,
                upcomingTasks,
                myProjectsDtos,
                taskStatusCounts,
                overallCompletionPercentage
        );

        return ResponseEntity.ok(response);
    }

    private String getRoleName(Integer desigId) {
        if (desigId == null) return "Site Engineer";
        return designationRepository.findById(desigId)
                .map(com.bionova.entity.DesignationMaster::getDesigNm)
                .orElse("Site Engineer");
    }

    private String calculatePriority(TaskLive t) {
        if (t.getEndDt() != null && t.getEndDt().isBefore(LocalDate.now().plusDays(2))) {
            return "High";
        }
        if (t.getEndDt() != null && t.getEndDt().isBefore(LocalDate.now().plusDays(5))) {
            return "Medium";
        }
        return "Low";
    }
}
