package com.bionova.controller;

import com.bionova.entity.executive.*;
import com.bionova.repository.executive.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api/executive")
public class ExecutiveController {

    @Autowired
    private ExecutiveProjectPipelineRepository pipelineRepository;

    @Autowired
    private ExecutiveBudgetItemRepository budgetRepository;

    @Autowired
    private ExecutiveRevenueRecordRepository revenueRepository;

    @Autowired
    private ExecutiveComplianceRecordRepository complianceRepository;

    @Autowired
    private ExecutiveFundingSourceRepository fundingRepository;

    @Autowired
    private ExecutiveEscrowAccountRepository escrowRepository;

    @Autowired
    private ExecutiveAlertRepository alertRepository;

    // --- Cockpit & High Level KPIs ---
    @GetMapping("/cockpit-kpis")
    public ResponseEntity<Map<String, Object>> getCockpitKpis() {
        Map<String, Object> kpis = new HashMap<>();

        List<ExecutiveProjectPipeline> projects = pipelineRepository.findAll();
        double totalCapexApproved = projects.stream().mapToDouble(p -> p.getCapexApproved() != null ? p.getCapexApproved() : 0.0).sum();
        double totalCapexSpent = projects.stream().mapToDouble(p -> p.getCapexSpent() != null ? p.getCapexSpent() : 0.0).sum();
        long activeProjectsCount = projects.size();

        List<ExecutiveRevenueRecord> revenues = revenueRepository.findAll();
        double totalRevenue = revenues.stream().mapToDouble(r -> r.getAmount() != null ? r.getAmount() : 0.0).sum();

        List<ExecutiveBudgetItem> budgets = budgetRepository.findAll();
        double baselineTotal = budgets.stream().mapToDouble(b -> b.getBaselineBudget() != null ? b.getBaselineBudget() : 0.0).sum();
        double actualTotal = budgets.stream().mapToDouble(b -> b.getActualIncurred() != null ? b.getActualIncurred() : 0.0).sum();

        List<ExecutiveComplianceRecord> complianceList = complianceRepository.findAll();
        long activeCompliances = complianceList.size();

        List<ExecutiveAlert> activeAlerts = alertRepository.findAll().stream().filter(a -> "Active".equalsIgnoreCase(a.getStatus())).toList();

        kpis.put("totalCapexApprovedCr", totalCapexApproved);
        kpis.put("totalCapexSpentCr", totalCapexSpent);
        kpis.put("activeProjectsCount", activeProjectsCount);
        kpis.put("totalRevenueInr", totalRevenue);
        kpis.put("baselineBudgetCr", baselineTotal);
        kpis.put("actualBudgetCr", actualTotal);
        kpis.put("totalCompliances", activeCompliances);
        kpis.put("activeAlertsCount", activeAlerts.size());

        return ResponseEntity.ok(kpis);
    }

    // --- 1. Pipeline Projects ---
    @GetMapping("/pipeline")
    public List<ExecutiveProjectPipeline> getPipeline() {
        return pipelineRepository.findAll();
    }

    @PostMapping("/pipeline")
    public ResponseEntity<ExecutiveProjectPipeline> createProject(@RequestBody ExecutiveProjectPipeline project) {
        if (project.getProjectCode() == null || project.getProjectCode().isEmpty()) {
            project.setProjectCode("EXP-" + (System.currentTimeMillis() % 10000));
        }
        return ResponseEntity.ok(pipelineRepository.save(project));
    }

    @PutMapping("/pipeline/{id}")
    public ResponseEntity<ExecutiveProjectPipeline> updateProject(@PathVariable Long id, @RequestBody ExecutiveProjectPipeline updated) {
        return pipelineRepository.findById(id).map(p -> {
            p.setName(updated.getName());
            p.setType(updated.getType());
            p.setLocation(updated.getLocation());
            p.setCapacity(updated.getCapacity());
            p.setStage(updated.getStage());
            p.setTargetCommissioning(updated.getTargetCommissioning());
            p.setStartDate(updated.getStartDate());
            p.setCompletionPct(updated.getCompletionPct());
            p.setCapexApproved(updated.getCapexApproved());
            p.setCapexSpent(updated.getCapexSpent());
            p.setLeadPM(updated.getLeadPM());
            p.setStatus(updated.getStatus());
            p.setUpcomingMilestone(updated.getUpcomingMilestone());
            return ResponseEntity.ok(pipelineRepository.save(p));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/pipeline/{id}")
    public ResponseEntity<Void> deleteProject(@PathVariable Long id) {
        if (!pipelineRepository.existsById(id)) return ResponseEntity.notFound().build();
        pipelineRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 2. Budget Items & Cost Centers ---
    @GetMapping("/budget")
    public List<ExecutiveBudgetItem> getBudgetItems() {
        return budgetRepository.findAll();
    }

    @PostMapping("/budget")
    public ResponseEntity<ExecutiveBudgetItem> createBudgetItem(@RequestBody ExecutiveBudgetItem item) {
        if (item.getCostCenterCode() == null || item.getCostCenterCode().isEmpty()) {
            item.setCostCenterCode("CC-" + (System.currentTimeMillis() % 10000));
        }
        return ResponseEntity.ok(budgetRepository.save(item));
    }

    @PutMapping("/budget/{id}")
    public ResponseEntity<ExecutiveBudgetItem> updateBudgetItem(@PathVariable Long id, @RequestBody ExecutiveBudgetItem updated) {
        return budgetRepository.findById(id).map(b -> {
            b.setName(updated.getName());
            b.setNature(updated.getNature());
            b.setPlant(updated.getPlant());
            b.setBaselineBudget(updated.getBaselineBudget());
            b.setActualIncurred(updated.getActualIncurred());
            b.setCommittedPO(updated.getCommittedPO());
            b.setLeadDept(updated.getLeadDept());
            b.setNotes(updated.getNotes());
            return ResponseEntity.ok(budgetRepository.save(b));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/budget/{id}")
    public ResponseEntity<Void> deleteBudgetItem(@PathVariable Long id) {
        if (!budgetRepository.existsById(id)) return ResponseEntity.notFound().build();
        budgetRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 3. Revenue Records ---
    @GetMapping("/revenue")
    public List<ExecutiveRevenueRecord> getRevenue() {
        return revenueRepository.findAll();
    }

    @PostMapping("/revenue")
    public ResponseEntity<ExecutiveRevenueRecord> createRevenue(@RequestBody ExecutiveRevenueRecord rev) {
        if (rev.getInvoiceCode() == null || rev.getInvoiceCode().isEmpty()) {
            rev.setInvoiceCode("REV-" + (System.currentTimeMillis() % 100000));
        }
        return ResponseEntity.ok(revenueRepository.save(rev));
    }

    @PutMapping("/revenue/{id}")
    public ResponseEntity<ExecutiveRevenueRecord> updateRevenue(@PathVariable Long id, @RequestBody ExecutiveRevenueRecord updated) {
        return revenueRepository.findById(id).map(r -> {
            r.setStream(updated.getStream());
            r.setOfftaker(updated.getOfftaker());
            r.setVolume(updated.getVolume());
            r.setUnitRate(updated.getUnitRate());
            r.setAmount(updated.getAmount());
            r.setInvoiceDate(updated.getInvoiceDate());
            r.setDueDate(updated.getDueDate());
            r.setPaymentStatus(updated.getPaymentStatus());
            r.setUtr(updated.getUtr());
            r.setPlant(updated.getPlant());
            return ResponseEntity.ok(revenueRepository.save(r));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/revenue/{id}")
    public ResponseEntity<Void> deleteRevenue(@PathVariable Long id) {
        if (!revenueRepository.existsById(id)) return ResponseEntity.notFound().build();
        revenueRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 4. Compliance & ESG ---
    @GetMapping("/compliance")
    public List<ExecutiveComplianceRecord> getCompliance() {
        return complianceRepository.findAll();
    }

    @PostMapping("/compliance")
    public ResponseEntity<ExecutiveComplianceRecord> createCompliance(@RequestBody ExecutiveComplianceRecord comp) {
        if (comp.getComplianceCode() == null || comp.getComplianceCode().isEmpty()) {
            comp.setComplianceCode("COMP-" + (System.currentTimeMillis() % 10000));
        }
        return ResponseEntity.ok(complianceRepository.save(comp));
    }

    @PutMapping("/compliance/{id}")
    public ResponseEntity<ExecutiveComplianceRecord> updateCompliance(@PathVariable Long id, @RequestBody ExecutiveComplianceRecord updated) {
        return complianceRepository.findById(id).map(c -> {
            c.setTitle(updated.getTitle());
            c.setAuthority(updated.getAuthority());
            c.setPlant(updated.getPlant());
            c.setCategory(updated.getCategory());
            c.setLicenseNo(updated.getLicenseNo());
            c.setIssueDate(updated.getIssueDate());
            c.setExpiryDate(updated.getExpiryDate());
            c.setEsgPillar(updated.getEsgPillar());
            c.setRiskLevel(updated.getRiskLevel());
            c.setStatus(updated.getStatus());
            c.setOfficer(updated.getOfficer());
            c.setAuditScore(updated.getAuditScore());
            return ResponseEntity.ok(complianceRepository.save(c));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/compliance/{id}")
    public ResponseEntity<Void> deleteCompliance(@PathVariable Long id) {
        if (!complianceRepository.existsById(id)) return ResponseEntity.notFound().build();
        complianceRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 5. Treasury & Funding Sources ---
    @GetMapping("/treasury")
    public List<ExecutiveFundingSource> getFundingSources() {
        return fundingRepository.findAll();
    }

    @PostMapping("/treasury")
    public ResponseEntity<ExecutiveFundingSource> createFundingSource(@RequestBody ExecutiveFundingSource src) {
        if (src.getFacilityCode() == null || src.getFacilityCode().isEmpty()) {
            src.setFacilityCode("TR-" + (System.currentTimeMillis() % 10000));
        }
        return ResponseEntity.ok(fundingRepository.save(src));
    }

    @PutMapping("/treasury/{id}")
    public ResponseEntity<ExecutiveFundingSource> updateFundingSource(@PathVariable Long id, @RequestBody ExecutiveFundingSource updated) {
        return fundingRepository.findById(id).map(f -> {
            f.setName(updated.getName());
            f.setType(updated.getType());
            f.setInstitution(updated.getInstitution());
            f.setSanctioned(updated.getSanctioned());
            f.setReceived(updated.getReceived());
            f.setOutstanding(updated.getOutstanding());
            f.setInterestRate(updated.getInterestRate());
            f.setTenor(updated.getTenor());
            f.setTarget(updated.getTarget());
            f.setStatus(updated.getStatus());
            return ResponseEntity.ok(fundingRepository.save(f));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/treasury/{id}")
    public ResponseEntity<Void> deleteFundingSource(@PathVariable Long id) {
        if (!fundingRepository.existsById(id)) return ResponseEntity.notFound().build();
        fundingRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 6. Escrow Accounts ---
    @GetMapping("/escrow")
    public List<ExecutiveEscrowAccount> getEscrowAccounts() {
        return escrowRepository.findAll();
    }

    @PostMapping("/escrow")
    public ResponseEntity<ExecutiveEscrowAccount> createEscrowAccount(@RequestBody ExecutiveEscrowAccount esc) {
        if (esc.getEscrowCode() == null || esc.getEscrowCode().isEmpty()) {
            esc.setEscrowCode("ESC-" + (System.currentTimeMillis() % 10000));
        }
        return ResponseEntity.ok(escrowRepository.save(esc));
    }

    @PutMapping("/escrow/{id}")
    public ResponseEntity<ExecutiveEscrowAccount> updateEscrowAccount(@PathVariable Long id, @RequestBody ExecutiveEscrowAccount updated) {
        return escrowRepository.findById(id).map(e -> {
            e.setAccountNo(updated.getAccountNo());
            e.setTitle(updated.getTitle());
            e.setCustodian(updated.getCustodian());
            e.setPlant(updated.getPlant());
            e.setCategory(updated.getCategory());
            e.setInflow(updated.getInflow());
            e.setOutflow(updated.getOutflow());
            e.setBalance(updated.getBalance());
            e.setDsraRequirement(updated.getDsraRequirement());
            e.setCovenantStatus(updated.getCovenantStatus());
            e.setLastAuditDate(updated.getLastAuditDate());
            e.setSignatory(updated.getSignatory());
            return ResponseEntity.ok(escrowRepository.save(e));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/escrow/{id}")
    public ResponseEntity<Void> deleteEscrowAccount(@PathVariable Long id) {
        if (!escrowRepository.existsById(id)) return ResponseEntity.notFound().build();
        escrowRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 7. Executive Alerts ---
    @GetMapping("/alerts")
    public List<ExecutiveAlert> getAlerts() {
        return alertRepository.findAll();
    }

    @PostMapping("/alerts")
    public ResponseEntity<ExecutiveAlert> createAlert(@RequestBody ExecutiveAlert alert) {
        if (alert.getAlertCode() == null || alert.getAlertCode().isEmpty()) {
            alert.setAlertCode("ALT-" + (System.currentTimeMillis() % 10000));
        }
        if (alert.getStatus() == null) alert.setStatus("Active");
        return ResponseEntity.ok(alertRepository.save(alert));
    }

    @PutMapping("/alerts/{id}")
    public ResponseEntity<ExecutiveAlert> updateAlert(@PathVariable Long id, @RequestBody ExecutiveAlert updated) {
        return alertRepository.findById(id).map(a -> {
            a.setTitle(updated.getTitle());
            a.setCategory(updated.getCategory());
            a.setSeverity(updated.getSeverity());
            a.setPlant(updated.getPlant());
            a.setTriggerDetail(updated.getTriggerDetail());
            a.setMetric(updated.getMetric());
            a.setAction(updated.getAction());
            a.setTimestamp(updated.getTimestamp());
            a.setStatus(updated.getStatus());
            return ResponseEntity.ok(alertRepository.save(a));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/alerts/{id}/resolve")
    public ResponseEntity<ExecutiveAlert> resolveAlert(@PathVariable Long id) {
        return alertRepository.findById(id).map(a -> {
            a.setStatus("Resolved");
            return ResponseEntity.ok(alertRepository.save(a));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/alerts/{id}")
    public ResponseEntity<Void> deleteAlert(@PathVariable Long id) {
        if (!alertRepository.existsById(id)) return ResponseEntity.notFound().build();
        alertRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

