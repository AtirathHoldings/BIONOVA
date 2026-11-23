package com.bionova.controller;

import com.bionova.entity.assetmaintenance.*;
import com.bionova.repository.assetmaintenance.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/asset-maintenance")
public class AssetMaintenanceController {

    @Autowired
    private MachineryAssetRepository assetRepository;

    @Autowired
    private MaintenanceScheduleRepository scheduleRepository;

    @Autowired
    private BreakdownIncidentRepository incidentRepository;

    @Autowired
    private ServicingCostLogRepository costLogRepository;

    // --- Assets ---
    @GetMapping("/assets")
    public List<MachineryAsset> getAssets() {
        return assetRepository.findAll();
    }

    @PostMapping("/assets")
    public ResponseEntity<MachineryAsset> createAsset(@RequestBody MachineryAsset asset) {
        asset.setId(null);
        return ResponseEntity.ok(assetRepository.save(asset));
    }

    @PutMapping("/assets/{id}")
    public ResponseEntity<MachineryAsset> updateAsset(@PathVariable Long id, @RequestBody MachineryAsset updated) {
        return assetRepository.findById(id).map(existing -> {
            existing.setAssetCode(updated.getAssetCode());
            existing.setName(updated.getName());
            existing.setCategory(updated.getCategory());
            existing.setFacility(updated.getFacility());
            existing.setOemManufacturer(updated.getOemManufacturer());
            existing.setModelSerial(updated.getModelSerial());
            existing.setCommissionDate(updated.getCommissionDate());
            existing.setCriticality(updated.getCriticality());
            existing.setOperatingStatus(updated.getOperatingStatus());
            return ResponseEntity.ok(assetRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/assets/{id}")
    public ResponseEntity<Void> deleteAsset(@PathVariable Long id) {
        if (!assetRepository.existsById(id)) return ResponseEntity.notFound().build();
        assetRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Schedules ---
    @GetMapping("/schedules")
    public List<MaintenanceSchedule> getSchedules() {
        return scheduleRepository.findAll();
    }

    @PostMapping("/schedules")
    public ResponseEntity<MaintenanceSchedule> createSchedule(@RequestBody MaintenanceSchedule schedule) {
        schedule.setId(null);
        return ResponseEntity.ok(scheduleRepository.save(schedule));
    }

    @PutMapping("/schedules/{id}")
    public ResponseEntity<MaintenanceSchedule> updateSchedule(@PathVariable Long id, @RequestBody MaintenanceSchedule updated) {
        return scheduleRepository.findById(id).map(existing -> {
            existing.setScheduleCode(updated.getScheduleCode());
            existing.setAssetName(updated.getAssetName());
            existing.setFacility(updated.getFacility());
            existing.setFrequency(updated.getFrequency());
            existing.setNextDueDate(updated.getNextDueDate());
            existing.setMeterThresholdHrs(updated.getMeterThresholdHrs());
            existing.setChecklistItems(updated.getChecklistItems());
            existing.setLeadTechnician(updated.getLeadTechnician());
            existing.setStatus(updated.getStatus());
            return ResponseEntity.ok(scheduleRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/schedules/{id}")
    public ResponseEntity<Void> deleteSchedule(@PathVariable Long id) {
        if (!scheduleRepository.existsById(id)) return ResponseEntity.notFound().build();
        scheduleRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Incidents ---
    @GetMapping("/incidents")
    public List<BreakdownIncident> getIncidents() {
        return incidentRepository.findAll();
    }

    @PostMapping("/incidents")
    public ResponseEntity<BreakdownIncident> createIncident(@RequestBody BreakdownIncident incident) {
        incident.setId(null);
        return ResponseEntity.ok(incidentRepository.save(incident));
    }

    @PutMapping("/incidents/{id}")
    public ResponseEntity<BreakdownIncident> updateIncident(@PathVariable Long id, @RequestBody BreakdownIncident updated) {
        return incidentRepository.findById(id).map(existing -> {
            existing.setTicketNumber(updated.getTicketNumber());
            existing.setFacility(updated.getFacility());
            existing.setAssetName(updated.getAssetName());
            existing.setReportedTime(updated.getReportedTime());
            existing.setSeverity(updated.getSeverity());
            existing.setSymptomDescription(updated.getSymptomDescription());
            existing.setDowntimeHours(updated.getDowntimeHours());
            existing.setRootCause(updated.getRootCause());
            existing.setCorrectiveAction(updated.getCorrectiveAction());
            existing.setStatus(updated.getStatus());
            return ResponseEntity.ok(incidentRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/incidents/{id}")
    public ResponseEntity<Void> deleteIncident(@PathVariable Long id) {
        if (!incidentRepository.existsById(id)) return ResponseEntity.notFound().build();
        incidentRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Servicing Costs ---
    @GetMapping("/servicing-costs")
    public List<ServicingCostLog> getServicingCosts() {
        return costLogRepository.findAll();
    }

    @PostMapping("/servicing-costs")
    public ResponseEntity<ServicingCostLog> createServicingCost(@RequestBody ServicingCostLog costLog) {
        costLog.setId(null);
        return ResponseEntity.ok(costLogRepository.save(costLog));
    }

    @PutMapping("/servicing-costs/{id}")
    public ResponseEntity<ServicingCostLog> updateServicingCost(@PathVariable Long id, @RequestBody ServicingCostLog updated) {
        return costLogRepository.findById(id).map(existing -> {
            existing.setLogNumber(updated.getLogNumber());
            existing.setAssetName(updated.getAssetName());
            existing.setFacility(updated.getFacility());
            existing.setServiceDate(updated.getServiceDate());
            existing.setServiceNature(updated.getServiceNature());
            existing.setSparesConsumed(updated.getSparesConsumed());
            existing.setSparesCost(updated.getSparesCost());
            existing.setLaborCost(updated.getLaborCost());
            existing.setExternalVendorFee(updated.getExternalVendorFee());
            existing.setServicingVendor(updated.getServicingVendor());
            existing.setInvoiceRef(updated.getInvoiceRef());
            existing.setWarrantyCovered(updated.getWarrantyCovered());
            return ResponseEntity.ok(costLogRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/servicing-costs/{id}")
    public ResponseEntity<Void> deleteServicingCost(@PathVariable Long id) {
        if (!costLogRepository.existsById(id)) return ResponseEntity.notFound().build();
        costLogRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
