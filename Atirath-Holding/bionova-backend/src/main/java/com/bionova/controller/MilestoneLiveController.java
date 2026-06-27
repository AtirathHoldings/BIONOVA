package com.bionova.controller;

import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/milestone-live")
public class MilestoneLiveController {

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @GetMapping
    public List<MilestoneLive> getAll() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return employeeRepository.findByEmail(email)
                .map(employee -> {
                    if ("admin".equalsIgnoreCase(employee.getRole()) || "manager".equalsIgnoreCase(employee.getRole())) {
                        return milestoneLiveRepository.findAll();
                    } else {
                        return milestoneLiveRepository.findMilestonesByEmpId(employee.getEmpId());
                    }
                })
                .orElse(List.of());
    }

    @GetMapping("/by-employee/{empId}")
    public ResponseEntity<?> getMilestonesByEmployee(@PathVariable Long empId) {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);
        if (employee == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("message", "Unauthorized"));
        }

        if ("admin".equalsIgnoreCase(employee.getRole()) || 
            "manager".equalsIgnoreCase(employee.getRole()) || 
            employee.getEmpId().equals(empId)) {
            return ResponseEntity.ok(milestoneLiveRepository.findMilestonesByEmpId(empId));
        } else {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("message", "Access denied"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<MilestoneLive> getById(@PathVariable Long id) {
        return milestoneLiveRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-project/{prjId}")
    public List<MilestoneLive> getByProject(@PathVariable Long prjId) {
        return milestoneLiveRepository.findByPrjId(prjId);
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody MilestoneLive milestone) {
        if (milestone.getMlstnCd() != null && !milestone.getMlstnCd().trim().isEmpty()) {
            if (milestoneLiveRepository.existsByMlstnCd(milestone.getMlstnCd())) {
                return ResponseEntity.badRequest().body(Map.of("message", "Milestone code already exists."));
            }
        }

        ProjectLive project = projectLiveRepository.findById(milestone.getPrjId())
                .orElseThrow(() -> new RuntimeException("Project not found with ID: " + milestone.getPrjId()));

        if (milestone.getMlstnSts() == null) {
            milestone.setMlstnSts("LIVE");
        }
        if (milestone.getSts() == null) {
            milestone.setSts(true);
        }

        // Auto-compute dates or days
        if (milestone.getStDt() != null && milestone.getMlstnDays() != null) {
            milestone.setEndDt(milestone.getStDt().plusDays(milestone.getMlstnDays()));
        } else if (milestone.getStDt() != null && milestone.getEndDt() != null) {
            long days = java.time.temporal.ChronoUnit.DAYS.between(milestone.getStDt(), milestone.getEndDt());
            milestone.setMlstnDays((int) days);
        }

        MilestoneLive saved = milestoneLiveRepository.save(milestone);

        // Validate limits
        String warning = null;
        if (saved.getStDt() != null && saved.getEndDt() != null) {
            if (saved.getStDt().isBefore(project.getStDt()) ||
                (project.getEndDt() != null && saved.getEndDt().isAfter(project.getEndDt())) ||
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
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody MilestoneLive details) {
        MilestoneLive milestone = milestoneLiveRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Milestone not found: " + id));

        if (details.getMlstnCd() != null && !details.getMlstnCd().trim().isEmpty()) {
            if (milestoneLiveRepository.existsByMlstnCdAndMIdNot(details.getMlstnCd(), id)) {
                return ResponseEntity.badRequest().body(Map.of("message", "Milestone code already exists."));
            }
            milestone.setMlstnCd(details.getMlstnCd());
        }

        milestone.setPrjId(details.getPrjId());
        milestone.setMlstnTtl(details.getMlstnTtl());
        milestone.setMlstnDesc(details.getMlstnDesc());
        milestone.setMlstnDepFlg(details.getMlstnDepFlg());
        milestone.setMlstnDepTyp(details.getMlstnDepTyp());
        milestone.setMlstnDepMId(details.getMlstnDepMId());

        // Auto-compute dates or days based on changes
        if (details.getStDt() != null && details.getMlstnDays() != null) {
            milestone.setStDt(details.getStDt());
            milestone.setMlstnDays(details.getMlstnDays());
            milestone.setEndDt(details.getStDt().plusDays(details.getMlstnDays()));
        } else if (details.getStDt() != null && details.getEndDt() != null) {
            milestone.setStDt(details.getStDt());
            milestone.setEndDt(details.getEndDt());
            long days = java.time.temporal.ChronoUnit.DAYS.between(details.getStDt(), details.getEndDt());
            milestone.setMlstnDays((int) days);
        } else {
            milestone.setMlstnDays(details.getMlstnDays());
            milestone.setStDt(details.getStDt());
            milestone.setEndDt(details.getEndDt());
        }

        milestone.setChkId(details.getChkId());
        milestone.setAddlRem(details.getAddlRem());
        milestone.setSts(details.getSts());
        if (details.getMlstnSts() != null) {
            milestone.setMlstnSts(details.getMlstnSts());
        }

        MilestoneLive saved = milestoneLiveRepository.save(milestone);

        ProjectLive project = projectLiveRepository.findById(saved.getPrjId())
                .orElseThrow(() -> new RuntimeException("Project not found with ID: " + saved.getPrjId()));

        String warning = null;
        if (saved.getStDt() != null && saved.getEndDt() != null) {
            if (saved.getStDt().isBefore(project.getStDt()) ||
                (project.getEndDt() != null && saved.getEndDt().isAfter(project.getEndDt())) ||
                (saved.getMlstnDays() != null && project.getNoOfDays() != null && saved.getMlstnDays() > project.getNoOfDays())) {
                warning = "Warning: Milestone dates/days exceed project limits. You must also update the Project dates/days accordingly.";
            }
        }

        // Check if tasks under this milestone exceed updated limits
        if (warning == null) {
            List<TaskLive> tasks = taskLiveRepository.findByMilestoneId(id);
            for (TaskLive task : tasks) {
                if (task.getStDt().isBefore(saved.getStDt()) ||
                    (saved.getEndDt() != null && task.getEndDt() != null && task.getEndDt().isAfter(saved.getEndDt())) ||
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

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> body) {
        MilestoneLive ms = milestoneLiveRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Milestone not found: " + id));

        String newStatus = body.get("mlstnSts");
        if (!List.of("LIVE", "HOLD", "COMPLETED", "CLOSED").contains(newStatus)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid status. Allowed: LIVE, HOLD, COMPLETED, CLOSED"));
        }
        ms.setMlstnSts(newStatus);
        return ResponseEntity.ok(milestoneLiveRepository.save(ms));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        milestoneLiveRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
