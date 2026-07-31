package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.entity.ExternalEmployee;
import com.bionova.entity.ProjectAccess;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.TaskLive;
import com.bionova.entity.ProcessConfig;
import com.bionova.entity.ReviewerMaster;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.ProjectAccessRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.DepartmentRepository;
import com.bionova.repository.ProcessConfigRepository;
import com.bionova.repository.ReviewerMasterRepository;
import com.bionova.repository.ExternalEmployeeRepository;
import com.bionova.repository.CompanyRepository;
import com.bionova.repository.PlantRepository;
import com.bionova.service.ProjectLeadLagService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@RestController
@CrossOrigin
public class ProjectAccessController {

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private ProjectAccessRepository projectAccessRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    @Autowired
    private ProcessConfigRepository processConfigRepository;

    @Autowired
    private ReviewerMasterRepository reviewerMasterRepository;

    @Autowired
    private ExternalEmployeeRepository externalEmployeeRepository;

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private PlantRepository plantRepository;

    @Autowired
    private ProjectLeadLagService leadLagService;

    // Helper: format LocalDate to yyyy-MM-dd
    private String formatLocalDate(java.time.LocalDate date) {
        if (date == null) return "";
        return date.format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
    }

    // Helper: format task status
    private String formatTaskStatus(String status) {
        if (status == null) return "Pending";
        switch (status.toUpperCase()) {
            case "CLOSED":
            case "DONE":
                return "Closed";
            case "IN_PROGRESS":
            case "INPROGRESS":
            case "PROGRESS":
                return "In Progress";
            default:
                return "Pending";
        }
    }

    // Helper: resolve employee name and code
    private String resolveEmployeeNameAndCode(Long empId) {
        if (empId == null) return "Unassigned";
        return employeeRepository.findById(empId)
                .map(emp -> emp.getFirstName() + " " + (emp.getLastName() != null ? emp.getLastName() : "") + " (" + emp.getEmpCode() + ")")
                .orElse("Unassigned");
    }

    // Helper: resolve assignee name and code (internal or external)
    private String resolveAssigneeNameAndCode(TaskLive task) {
        if (task.getEmpId() != null) {
            return employeeRepository.findById(task.getEmpId())
                    .map(emp -> emp.getFirstName() + " " + (emp.getLastName() != null ? emp.getLastName() : "") + " (" + emp.getEmpCode() + ")")
                    .orElse("Unassigned");
        } else if (task.getExtEmpId() != null) {
            return externalEmployeeRepository.findById(task.getExtEmpId())
                    .map(ext -> ext.getExtEmpNm() + " (" + ext.getExtEmpCode() + ")")
                    .orElse("Unassigned");
        }
        return "Unassigned";
    }

    // Helper: resolve project manager dynamically
    private String resolveProjectManager(Long prjId) {
        List<ProjectAccess> accesses = projectAccessRepository.findByPrjIdAndSts(prjId, true);
        for (ProjectAccess pa : accesses) {
            if ("MANAGER".equalsIgnoreCase(pa.getAccessType())) {
                Employee manager = employeeRepository.findById(pa.getEmpId()).orElse(null);
                if (manager != null) {
                    return manager.getFirstName() + " " + (manager.getLastName() != null ? manager.getLastName() : "") + " (" + manager.getEmpCode() + ")";
                }
            }
        }
        // Fallback to employee with desigId = 4
        Employee managerEmp = employeeRepository.findAll().stream()
                .filter(e -> e.getDesigId() != null && e.getDesigId() == 4)
                .findFirst()
                .orElse(null);
        if (managerEmp != null) {
            return managerEmp.getFirstName() + " " + (managerEmp.getLastName() != null ? managerEmp.getLastName() : "") + " (" + managerEmp.getEmpCode() + ")";
        }
        return "Suresh Babu (EMP1009)"; // ultimate fallback
    }

    // 1. GET /api/projects/access -> Fetch all projects with access status for logged-in user
    @GetMapping("/api/projects/access")
    public ResponseEntity<?> getProjectsWithAccess() {
        try {
            String email = SecurityContextHolder.getContext().getAuthentication().getName();
            Employee currentEmp = employeeRepository.findByEmail(email).orElse(null);
            if (currentEmp == null) {
                return ResponseEntity.status(401).body(Map.of("error", "Unauthorized"));
            }

            List<ProjectLive> projects = projectLiveRepository.findAll();
            List<Map<String, Object>> response = new ArrayList<>();

            for (ProjectLive project : projects) {
                try {
                Optional<ProjectAccess> accessOpt = projectAccessRepository.findByPrjIdAndEmpIdAndSts(
                        project.getPrjId(), currentEmp.getEmpId(), true);

                // Fetch department name
                String deptName = "Operations";
                if (project.getDeptId() != null) {
                    var dept = departmentRepository.findById(project.getDeptId().longValue()).orElse(null);
                    if (dept != null) {
                        deptName = dept.getDeptNm();
                    }
                }

                // Fetch Client Name & Company Location
                String clientName = "";
                String companyLocation = "";
                if (project.getCoyId() != null) {
                    var coy = companyRepository.findById(project.getCoyId().longValue()).orElse(null);
                    if (coy != null) {
                        clientName = coy.getCoyNm();
                        companyLocation = coy.getCtVlg();
                    }
                }
                if (clientName == null || clientName.isEmpty()) {
                    List<com.bionova.entity.CompanyMaster> allCompanies = companyRepository.findAll();
                    if (!allCompanies.isEmpty()) {
                        clientName = allCompanies.get(0).getCoyNm();
                        companyLocation = allCompanies.get(0).getCtVlg();
                    } else {
                        clientName = "";
                        companyLocation = "";
                    }
                }

                String plantName = "";
                if (project.getPltId() != null) {
                    var plt = plantRepository.findById(project.getPltId().longValue()).orElse(null);
                    if (plt != null) {
                        plantName = plt.getPltNm();
                    }
                }
                if (plantName == null || plantName.isEmpty()) {
                    List<com.bionova.entity.PlantMaster> allPlants = plantRepository.findAll();
                    if (!allPlants.isEmpty()) {
                        plantName = allPlants.get(0).getPltNm();
                    } else {
                        plantName = "";
                    }
                }

                // Fetch milestones and tasks stats
                int totalTasks = 0;
                int completedTasks = 0;
                int totalMilestones = 0;
                int completedMilestones = 0;
                List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(project.getPrjId());
                totalMilestones = milestones.size();
                for (MilestoneLive ms : milestones) {
                    List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(ms.getMId());
                    totalTasks += tasks.size();
                    boolean msCompleted = false;
                    if (ms.getMlstnSts() != null && "CLOSED".equalsIgnoreCase(ms.getMlstnSts())) {
                        msCompleted = true;
                    } else if (!tasks.isEmpty()) {
                        boolean allCompleted = true;
                        for (TaskLive task : tasks) {
                            String statusNm = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
                            if (!"CLOSED".equalsIgnoreCase(statusNm)) {
                                allCompleted = false;
                                break;
                            }
                        }
                        if (allCompleted) {
                            msCompleted = true;
                        }
                    }
                    if (msCompleted) {
                        completedMilestones++;
                    }
                    for (TaskLive task : tasks) {
                        String statusNm = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
                        if ("CLOSED".equalsIgnoreCase(statusNm)) {
                            completedTasks++;
                        }
                    }
                }

                double progressPercent = 0.0;
                try {
                    Map<String, Object> ll = leadLagService.getLeadLagDetail(project.getPrjId());
                    Object ap = ll.get("actualProgress");
                    if (ap instanceof Number n) {
                        progressPercent = n.doubleValue();
                    }
                } catch (Exception ignored) {}
                int progress = (int) Math.round(progressPercent);

                // Collect assigned employee IDs
                Set<String> assignedEmpIds = new HashSet<>();
                // 1. From tasks
                for (MilestoneLive ms : milestones) {
                    List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(ms.getMId());
                    for (TaskLive task : tasks) {
                        if (task.getEmpId() != null) {
                            assignedEmpIds.add(task.getEmpId().toString());
                        }
                    }
                }
                // 2. From project access
                List<ProjectAccess> projectAccesses = projectAccessRepository.findByPrjIdAndSts(project.getPrjId(), true);
                for (ProjectAccess pa : projectAccesses) {
                    assignedEmpIds.add(pa.getEmpId().toString());
                }

                String managerName = resolveProjectManager(project.getPrjId());

                boolean hasAccess = accessOpt.isPresent() || assignedEmpIds.contains(currentEmp.getEmpId().toString());
                String accessType = accessOpt.isPresent() ? accessOpt.get().getAccessType() : "Team Member";

                Map<String, Object> prjMap = new HashMap<>();
                prjMap.put("id", project.getPrjId().toString());
                prjMap.put("prjId", project.getPrjId());
                prjMap.put("prjCd", project.getPrjCd());
                prjMap.put("prjNm", project.getPrjNm());
                prjMap.put("prjSts", project.getPrjSts());
                
                prjMap.put("name", project.getPrjNm());
                prjMap.put("code", project.getPrjCd());
                prjMap.put("description", project.getPrjDesc());
                prjMap.put("status", project.getPrjSts() != null ? project.getPrjSts().toLowerCase() : "");
                prjMap.put("progress", progress);
                prjMap.put("startDate", formatLocalDate(project.getStDt()));
                prjMap.put("endDate", formatLocalDate(project.getEndDt()));
                prjMap.put("manager", managerName);
                prjMap.put("department", deptName);
                prjMap.put("clientName", clientName);
                prjMap.put("client", clientName);
                prjMap.put("plantName", plantName);
                prjMap.put("plant", plantName);
                prjMap.put("location", companyLocation);

                prjMap.put("projectType", "Construction");
                prjMap.put("type", "Construction");
                prjMap.put("assignedEmployees", new ArrayList<>(assignedEmpIds));
                prjMap.put("priority", project.getPrjPrty() != null ? project.getPrjPrty().getPriorityNm().toLowerCase() : "medium");

                Map<String, Object> tasksMap = new HashMap<>();
                tasksMap.put("total", totalTasks);
                tasksMap.put("completed", completedTasks);
                prjMap.put("tasks", tasksMap);

                Map<String, Object> milestonesMap = new HashMap<>();
                milestonesMap.put("total", totalMilestones);
                milestonesMap.put("completed", completedMilestones);
                prjMap.put("milestonesCount", milestonesMap);

                prjMap.put("has_access", hasAccess);
                prjMap.put("access_type", hasAccess ? accessType : "");

                response.add(prjMap);
                } catch (Exception projEx) {
                    // Skip this project if it causes a DB lock or other error
                    System.err.println("Skipping project " + project.getPrjId() + " due to error: " + projEx.getMessage());
                }
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }

    // 2. GET /api/projects/{prjId}/access -> Fetch accesses for a specific project
    @GetMapping("/api/projects/{prjId}/access")
    public ResponseEntity<?> getProjectAccessList(@PathVariable Long prjId) {
        try {
            ProjectLive project = projectLiveRepository.findById(prjId).orElse(null);
            if (project == null) {
                return ResponseEntity.status(404).body(Map.of("error", "Project not found"));
            }

            // Fetch department name
            String deptName = "Operations";
            if (project.getDeptId() != null) {
                var dept = departmentRepository.findById(project.getDeptId().longValue()).orElse(null);
                if (dept != null) {
                    deptName = dept.getDeptNm();
                }
            }

            // Fetch Client Name, Company Location & Plant Name
            String clientName = "";
            String companyLocation = "";
            if (project.getCoyId() != null) {
                var coy = companyRepository.findById(project.getCoyId().longValue()).orElse(null);
                if (coy != null) {
                    clientName = coy.getCoyNm();
                    companyLocation = coy.getCtVlg();
                }
            }
            if (clientName == null || clientName.isEmpty()) {
                List<com.bionova.entity.CompanyMaster> allCompanies = companyRepository.findAll();
                if (!allCompanies.isEmpty()) {
                    clientName = allCompanies.get(0).getCoyNm();
                    companyLocation = allCompanies.get(0).getCtVlg();
                } else {
                    clientName = "";
                    companyLocation = "";
                }
            }

            String plantName = "";
            if (project.getPltId() != null) {
                var plt = plantRepository.findById(project.getPltId().longValue()).orElse(null);
                if (plt != null) {
                    plantName = plt.getPltNm();
                }
            }
            if (plantName == null || plantName.isEmpty()) {
                List<com.bionova.entity.PlantMaster> allPlants = plantRepository.findAll();
                if (!allPlants.isEmpty()) {
                    plantName = allPlants.get(0).getPltNm();
                } else {
                    plantName = "";
                }
            }

            // Fetch milestones and tasks stats
            int totalTasks = 0;
            int completedTasks = 0;
            int totalMilestones = 0;
            int completedMilestones = 0;
            List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(prjId);
            totalMilestones = milestones.size();
            for (MilestoneLive ms : milestones) {
                List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(ms.getMId());
                totalTasks += tasks.size();
                boolean msCompleted = false;
                if (ms.getMlstnSts() != null && "CLOSED".equalsIgnoreCase(ms.getMlstnSts())) {
                    msCompleted = true;
                } else if (!tasks.isEmpty()) {
                    boolean allCompleted = true;
                    for (TaskLive task : tasks) {
                        String statusNm = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
                        if (!"CLOSED".equalsIgnoreCase(statusNm)) {
                            allCompleted = false;
                            break;
                        }
                    }
                    if (allCompleted) {
                        msCompleted = true;
                    }
                }
                if (msCompleted) {
                    completedMilestones++;
                }
                for (TaskLive task : tasks) {
                    String statusNm = task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "";
                    if ("CLOSED".equalsIgnoreCase(statusNm)) {
                        completedTasks++;
                    }
                }
            }

            double progressPercent = 0.0;
            try {
                Map<String, Object> ll = leadLagService.getLeadLagDetail(prjId);
                Object ap = ll.get("actualProgress");
                if (ap instanceof Number n) {
                    progressPercent = n.doubleValue();
                }
            } catch (Exception ignored) {}
            int progress = (int) Math.round(progressPercent);

            String managerName = resolveProjectManager(prjId);

            // Build project detail map
            Map<String, Object> prjMap = new HashMap<>();
            prjMap.put("id", project.getPrjId().toString());
            prjMap.put("prjId", project.getPrjId());
            prjMap.put("prjCd", project.getPrjCd());
            prjMap.put("prjNm", project.getPrjNm());
            prjMap.put("prjSts", project.getPrjSts());
            
            prjMap.put("name", project.getPrjNm());
            prjMap.put("code", project.getPrjCd());
            prjMap.put("description", project.getPrjDesc());
            prjMap.put("status", project.getPrjSts() != null ? project.getPrjSts().toLowerCase() : "");
            prjMap.put("progress", progress);
            prjMap.put("startDate", formatLocalDate(project.getStDt()));
            prjMap.put("endDate", formatLocalDate(project.getEndDt()));
            prjMap.put("manager", managerName);
            prjMap.put("department", deptName);
            prjMap.put("clientName", clientName);
            prjMap.put("client", clientName);
            prjMap.put("plantName", plantName);
            prjMap.put("plant", plantName);
            prjMap.put("location", companyLocation);
            prjMap.put("projectType", "Construction");
            prjMap.put("type", "Construction");
            prjMap.put("priority", project.getPrjPrty() != null ? project.getPrjPrty().getPriorityNm().toLowerCase() : "medium");

            Map<String, Object> milestonesMap = new HashMap<>();
            milestonesMap.put("total", totalMilestones);
            milestonesMap.put("completed", completedMilestones);
            prjMap.put("milestonesCount", milestonesMap);

            Map<String, Object> tasksMap = new HashMap<>();
            tasksMap.put("total", totalTasks);
            tasksMap.put("completed", completedTasks);
            prjMap.put("tasks", tasksMap);

            List<ProjectAccess> accesses = projectAccessRepository.findByPrjIdAndSts(prjId, true);
            List<Map<String, Object>> accessDetails = new ArrayList<>();
            Set<String> assignedEmpIds = new HashSet<>();

            // Add explicitly granted accesses
            for (ProjectAccess access : accesses) {
                Employee emp = employeeRepository.findById(access.getEmpId()).orElse(null);
                if (emp != null) {
                    assignedEmpIds.add(access.getEmpId().toString());

                    Map<String, Object> details = new HashMap<>();
                    details.put("pac_id", access.getPacId());
                    details.put("emp_id", access.getEmpId().toString());
                    details.put("access_type", access.getAccessType());
                    details.put("granted_at", access.getGrantedAt());
                    details.put("sts", access.getSts());

                    Map<String, Object> empMap = new HashMap<>();
                    empMap.put("name", emp.getFirstName() + " " + (emp.getLastName() != null ? emp.getLastName() : ""));
                    empMap.put("code", emp.getEmpCode());
                    empMap.put("email", emp.getEmail());

                    details.put("employee", empMap);
                    accessDetails.add(details);
                }
            }

            // Also ensure employees assigned to tasks are marked as assigned to the project
            for (MilestoneLive ms : milestones) {
                List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(ms.getMId());
                for (TaskLive task : tasks) {
                    if (task.getEmpId() != null) {
                        assignedEmpIds.add(task.getEmpId().toString());
                    } else if (task.getExtEmpId() != null) {
                        assignedEmpIds.add(task.getExtEmpId().toString());
                    }
                }
            }

            Map<String, Object> response = new HashMap<>();
            response.put("project", prjMap);
            response.put("accesses", accessDetails);
            response.put("assignedEmployees", new ArrayList<>(assignedEmpIds));

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }

    // 3. GET /api/projects/{prjId}/milestones-with-tasks -> Fetch project milestones and tasks dynamically
    @GetMapping("/api/projects/{prjId}/milestones-with-tasks")
    public ResponseEntity<?> getProjectMilestonesWithTasks(@PathVariable Long prjId) {
        try {
            List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(prjId);
            List<Map<String, Object>> msList = new ArrayList<>();
            
            for (MilestoneLive ms : milestones) {
                Map<String, Object> msMap = new HashMap<>();
                msMap.put("id", ms.getMId().toString());
                msMap.put("name", ms.getMlstnTtl());
                
                List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(ms.getMId());
                List<Map<String, Object>> taskList = new ArrayList<>();
                for (TaskLive task : tasks) {
                    Map<String, Object> tMap = new HashMap<>();
                    tMap.put("id", task.getTaskId().toString());
                    tMap.put("name", task.getTaskNm());
                    tMap.put("taskCode", task.getTaskCd());
                    String resolvedStatus = "Pending";
                    if (task.getTaskSts() != null) {
                        String baseStatus = task.getTaskSts().getStatusNm();
                        if ("CLOSED".equalsIgnoreCase(baseStatus)) {
                            resolvedStatus = "Closed";
                        } else if ("IN_PROGRESS".equalsIgnoreCase(baseStatus)) {
                            resolvedStatus = "In Progress";
                        } else if ("OPEN".equalsIgnoreCase(baseStatus)) {
                            resolvedStatus = "Pending";
                        } else {
                            resolvedStatus = baseStatus;
                        }
                    }

                    // Check process status overrides
                    com.bionova.enums.ProcessStatus processSts = task.getProcessStatus();
                    if (processSts == com.bionova.enums.ProcessStatus.UNDER_REVIEW) {
                        resolvedStatus = "Under Review";
                    } else if (processSts == com.bionova.enums.ProcessStatus.REWORK) {
                        resolvedStatus = "Rework";
                    } else if (processSts == com.bionova.enums.ProcessStatus.REASSIGN) {
                        resolvedStatus = "Reassign";
                    }

                    // Check time status overrides (if not completed)
                    if (!"Closed".equalsIgnoreCase(resolvedStatus)) {
                        com.bionova.enums.TimeStatus timeSts = task.getTimeStatus();
                        if (timeSts == com.bionova.enums.TimeStatus.OVERDUE) {
                            resolvedStatus = "Overdue";
                        } else if (timeSts == com.bionova.enums.TimeStatus.DUE_TODAY) {
                            resolvedStatus = "Due Today";
                        }
                    }
                    tMap.put("status", resolvedStatus);
                    
                    // Resolve names
                    tMap.put("assignee", resolveAssigneeNameAndCode(task));
                    
                    // Resolve reviewer/approver from process config
                    List<ProcessConfig> configs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(task.getTaskId(), true);
                    String reviewerName = "Unassigned";
                    String approverName = "Unassigned";
                    for (ProcessConfig c : configs) {
                        if (c.getRId() != null) {
                            ReviewerMaster rm = reviewerMasterRepository.findById(c.getRId()).orElse(null);
                            if (rm != null) {
                                if ("Reviewer".equalsIgnoreCase(rm.getRNm()) && c.getEmpId() != null) {
                                    reviewerName = resolveEmployeeNameAndCode(c.getEmpId());
                                } else if ("Approver".equalsIgnoreCase(rm.getRNm()) && c.getEmpId() != null) {
                                    approverName = resolveEmployeeNameAndCode(c.getEmpId());
                                }
                            }
                        }
                    }
                    tMap.put("reviewer", reviewerName);
                    tMap.put("approver", approverName);
                    
                    taskList.add(tMap);
                }
                msMap.put("tasks", taskList);
                msList.add(msMap);
            }
            return ResponseEntity.ok(msList);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }

    // 4. POST /api/projects/{prjId}/access/bulk -> Grant access to multiple employees
    @PostMapping("/api/projects/{prjId}/access/bulk")
    public ResponseEntity<?> grantAccessBulk(@PathVariable Long prjId, @RequestBody Map<String, Object> body) {
        try {
            List<?> empIdsObj = (List<?>) body.get("employeeIds");
            String accessType = (String) body.get("accessType");
            String performedBy = (String) body.get("performedBy");
            String remarks = (String) body.get("remarks");

            if (empIdsObj == null || accessType == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "Missing employeeIds or accessType"));
            }

            for (Object obj : empIdsObj) {
                Long empId = Long.valueOf(obj.toString());
                Optional<ProjectAccess> accessOpt = projectAccessRepository.findByPrjIdAndEmpId(prjId, empId);

                ProjectAccess access;
                if (accessOpt.isPresent()) {
                    access = accessOpt.get();
                } else {
                    access = new ProjectAccess();
                    access.setPrjId(prjId);
                    access.setEmpId(empId);
                }
                access.setAccessType(accessType);
                access.setSts(true);
                access.setPerformedBy(performedBy);
                access.setRemarks(remarks);
                access.setGrantedAt(LocalDateTime.now());

                projectAccessRepository.save(access);
            }

            return ResponseEntity.ok(Map.of("message", "Access granted successfully"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }

    // 5. POST /api/projects/{prjId}/access -> Update access type for a single employee
    @PostMapping("/api/projects/{prjId}/access")
    public ResponseEntity<?> updateAccessType(@PathVariable Long prjId, @RequestBody Map<String, Object> body) {
        try {
            Long empId = Long.valueOf(body.get("empId").toString());
            String accessType = (String) body.get("accessType");
            String performedBy = (String) body.get("performedBy");
            String remarks = (String) body.get("remarks");

            Optional<ProjectAccess> accessOpt = projectAccessRepository.findByPrjIdAndEmpId(prjId, empId);
            ProjectAccess access;
            if (accessOpt.isPresent()) {
                access = accessOpt.get();
            } else {
                access = new ProjectAccess();
                access.setPrjId(prjId);
                access.setEmpId(empId);
            }
            access.setAccessType(accessType);
            access.setSts(true);
            access.setPerformedBy(performedBy);
            access.setRemarks(remarks);
            access.setGrantedAt(LocalDateTime.now());

            projectAccessRepository.save(access);
            return ResponseEntity.ok(Map.of("message", "Access updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }

    // 6. DELETE /api/projects/{prjId}/access/{empId} -> Revoke access for an employee
    @DeleteMapping("/api/projects/{prjId}/access/{empId}")
    public ResponseEntity<?> revokeAccess(@PathVariable Long prjId, @PathVariable Long empId, @RequestBody(required = false) Map<String, Object> body) {
        try {
            Optional<ProjectAccess> accessOpt = projectAccessRepository.findByPrjIdAndEmpId(prjId, empId);
            if (accessOpt.isPresent()) {
                ProjectAccess access = accessOpt.get();
                access.setSts(false);
                if (body != null) {
                    access.setPerformedBy((String) body.get("performedBy"));
                    access.setRemarks((String) body.get("remarks"));
                }
                projectAccessRepository.save(access);
                return ResponseEntity.ok(Map.of("message", "Access revoked successfully"));
            } else {
                return ResponseEntity.status(404).body(Map.of("error", "Access mapping not found"));
            }
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }

    // 7. GET /api/access-templates/project -> Returns template list (dummy list or empty list as required)
    @GetMapping("/api/access-templates/project")
    public ResponseEntity<?> getAccessTemplates() {
        return ResponseEntity.ok(List.of());
    }

    // 8. POST /api/projects/tasks/{taskId}/assign-role -> Assign or remove task assignee, reviewer, or approver
    @PostMapping("/api/projects/tasks/{taskId}/assign-role")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<?> assignTaskRole(
            @PathVariable Long taskId,
            @RequestBody Map<String, Object> body) {
        try {
            String roleType = (String) body.get("roleType");
            Object empIdObj = body.get("empId");
            Long empId = null;
            if (empIdObj != null && !empIdObj.toString().isEmpty()) {
                empId = Long.valueOf(empIdObj.toString());
                if (empId == 0) {
                    empId = null;
                }
            }

            TaskLive task = taskLiveRepository.findById(taskId)
                    .orElseThrow(() -> new RuntimeException("Task not found: " + taskId));

            if ("assignee".equalsIgnoreCase(roleType)) {
                task.setEmpId(empId);
                taskLiveRepository.save(task);
            } else if ("reviewer".equalsIgnoreCase(roleType) || "approver".equalsIgnoreCase(roleType)) {
                int ordrId = "reviewer".equalsIgnoreCase(roleType) ? 1 : 2;
                List<ProcessConfig> configs = processConfigRepository.findByTaskIdAndIsLiveOrderByOrdrIdAsc(taskId, true);
                ProcessConfig targetConfig = null;
                for (ProcessConfig pc : configs) {
                    if (pc.getOrdrId() != null && pc.getOrdrId() == ordrId) {
                        targetConfig = pc;
                        break;
                    }
                }

                if (empId == null) {
                    if (targetConfig != null) {
                        processConfigRepository.delete(targetConfig);
                    }
                } else {
                    if (targetConfig == null) {
                        targetConfig = new ProcessConfig();
                        targetConfig.setTaskId(taskId);
                        targetConfig.setIsLive(true);
                        targetConfig.setOrdrId(ordrId);
                        String roleName = (ordrId == 1) ? "Reviewer" : "Approver";
                        Integer rId = reviewerMasterRepository.findAll().stream()
                                .filter(r -> roleName.equalsIgnoreCase(r.getRNm()))
                                .findFirst()
                                .map(ReviewerMaster::getRId)
                                .orElseGet(() -> {
                                    ReviewerMaster rm = new ReviewerMaster();
                                    rm.setRNm(roleName);
                                    return reviewerMasterRepository.save(rm).getRId();
                                });
                        targetConfig.setRId(rId);
                    }
                    targetConfig.setEmpId(empId);
                    processConfigRepository.save(targetConfig);
                }
            } else {
                return ResponseEntity.badRequest().body(Map.of("error", "Invalid roleType. Must be assignee, reviewer, or approver"));
            }

            return ResponseEntity.ok(Map.of("message", "Task role assigned successfully"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", e.getMessage()));
        }
    }
}
