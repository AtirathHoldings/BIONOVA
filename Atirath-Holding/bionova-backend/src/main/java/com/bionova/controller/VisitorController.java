package com.bionova.controller;

import com.bionova.entity.visitor.*;
import com.bionova.repository.visitor.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@RestController
@RequestMapping("/api/visitors")
public class VisitorController {

    @Autowired
    private VisitorRecordRepository recordRepository;

    @Autowired
    private VisitorRequestRepository requestRepository;

    @Autowired
    private VisitorAppointmentRepository appointmentRepository;

    @Autowired
    private VisitorVehicleRepository vehicleRepository;

    @Autowired
    private VisitorMaterialInwardRepository materialInwardRepository;

    @Autowired
    private VisitorMaterialOutwardRepository materialOutwardRepository;

    @Autowired
    private VisitorSafetyClearanceRepository safetyClearanceRepository;

    @Autowired
    private VisitorConfigRepository configRepository;

    // --- Dashboard Summary Stats ---
    @GetMapping("/dashboard-stats")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        Map<String, Object> stats = new HashMap<>();
        List<VisitorRecord> records = recordRepository.findAll();
        long insideCount = records.stream().filter(r -> "Checked-In".equalsIgnoreCase(r.getStatus())).count();
        long overdueCount = records.stream().filter(r -> Boolean.TRUE.equals(r.getIsOverdue())).count();
        long expectedCount = records.stream().filter(r -> "Expected".equalsIgnoreCase(r.getStatus()) || "Approved".equalsIgnoreCase(r.getStatus())).count();
        long totalToday = records.size();

        long pendingApprovals = requestRepository.findAll().stream().filter(r -> "Pending".equalsIgnoreCase(r.getStatus())).count();
        long vehiclesInside = vehicleRepository.findAll().stream().filter(v -> "Inside".equalsIgnoreCase(v.getStatus())).count();
        long safetyCleared = safetyClearanceRepository.findAll().stream().filter(s -> "Cleared".equalsIgnoreCase(s.getStatus())).count();

        stats.put("currentlyInside", insideCount);
        stats.put("overdueVisitors", overdueCount);
        stats.put("expectedToday", expectedCount);
        stats.put("totalVisitors", totalToday);
        stats.put("pendingApprovals", pendingApprovals);
        stats.put("vehiclesInside", vehiclesInside);
        stats.put("safetyCleared", safetyCleared);

        return ResponseEntity.ok(stats);
    }

    // --- 1. Visitor Records (Desk, Pass, Check-In, Check-Out, History) ---
    @GetMapping("/records")
    public List<VisitorRecord> getAllRecords() {
        return recordRepository.findAll();
    }

    @PostMapping("/records")
    public ResponseEntity<VisitorRecord> createRecord(@RequestBody VisitorRecord record) {
        if (record.getPassNo() == null || record.getPassNo().isEmpty()) {
            record.setPassNo("GP-2026-" + (System.currentTimeMillis() % 10000));
        }
        if (record.getStatus() == null) {
            record.setStatus("Expected");
        }
        return ResponseEntity.ok(recordRepository.save(record));
    }

    @PutMapping("/records/{id}")
    public ResponseEntity<VisitorRecord> updateRecord(@PathVariable Long id, @RequestBody VisitorRecord updated) {
        return recordRepository.findById(id).map(r -> {
            r.setName(updated.getName());
            r.setPhone(updated.getPhone());
            r.setEmail(updated.getEmail());
            r.setOrganization(updated.getOrganization());
            r.setVisitorType(updated.getVisitorType());
            r.setPlantLocation(updated.getPlantLocation());
            r.setHostEmployee(updated.getHostEmployee());
            r.setDepartment(updated.getDepartment());
            r.setPurpose(updated.getPurpose());
            r.setExpectedInTime(updated.getExpectedInTime());
            r.setExpectedOutTime(updated.getExpectedOutTime());
            r.setActualInTime(updated.getActualInTime());
            r.setActualOutTime(updated.getActualOutTime());
            r.setStatus(updated.getStatus());
            r.setGovtIdType(updated.getGovtIdType());
            r.setGovtId(updated.getGovtId());
            r.setVehicleType(updated.getVehicleType());
            r.setVehicleNo(updated.getVehicleNo());
            r.setSafetyDisclaimerSigned(updated.getSafetyDisclaimerSigned());
            r.setPpeIssued(updated.getPpeIssued());
            r.setPpeItems(updated.getPpeItems());
            r.setBadgeRfid(updated.getBadgeRfid());
            r.setAssignedZones(updated.getAssignedZones());
            r.setEscortRequired(updated.getEscortRequired());
            r.setEscortName(updated.getEscortName());
            r.setIsOverdue(updated.getIsOverdue());
            r.setOverdueMinutes(updated.getOverdueMinutes());
            r.setRemarks(updated.getRemarks());
            return ResponseEntity.ok(recordRepository.save(r));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/records/{id}/check-in")
    public ResponseEntity<VisitorRecord> checkInVisitor(@PathVariable Long id) {
        return recordRepository.findById(id).map(r -> {
            r.setStatus("Checked-In");
            r.setActualInTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("hh:mm a")));
            return ResponseEntity.ok(recordRepository.save(r));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/records/{id}/check-out")
    public ResponseEntity<VisitorRecord> checkOutVisitor(@PathVariable Long id) {
        return recordRepository.findById(id).map(r -> {
            r.setStatus("Checked-Out");
            r.setActualOutTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("hh:mm a")));
            return ResponseEntity.ok(recordRepository.save(r));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/records/{id}")
    public ResponseEntity<Void> deleteRecord(@PathVariable Long id) {
        if (!recordRepository.existsById(id)) return ResponseEntity.notFound().build();
        recordRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 2. Visit Requests & Approvals ---
    @GetMapping("/requests")
    public List<VisitorRequest> getAllRequests() {
        return requestRepository.findAll();
    }

    @PostMapping("/requests")
    public ResponseEntity<VisitorRequest> createRequest(@RequestBody VisitorRequest req) {
        if (req.getReqCode() == null || req.getReqCode().isEmpty()) {
            req.setReqCode("REQ-" + (System.currentTimeMillis() % 100000));
        }
        if (req.getStatus() == null) {
            req.setStatus("Pending");
        }
        return ResponseEntity.ok(requestRepository.save(req));
    }

    @PutMapping("/requests/{id}")
    public ResponseEntity<VisitorRequest> updateRequest(@PathVariable Long id, @RequestBody VisitorRequest updated) {
        return requestRepository.findById(id).map(r -> {
            r.setRequesterName(updated.getRequesterName());
            r.setOrganization(updated.getOrganization());
            r.setEmail(updated.getEmail());
            r.setPhone(updated.getPhone());
            r.setVisitorCategory(updated.getVisitorCategory());
            r.setHostName(updated.getHostName());
            r.setPlantLocation(updated.getPlantLocation());
            r.setRequestedDate(updated.getRequestedDate());
            r.setRequestedTime(updated.getRequestedTime());
            r.setPurpose(updated.getPurpose());
            r.setVisitorCount(updated.getVisitorCount());
            r.setStatus(updated.getStatus());
            r.setRejectionReason(updated.getRejectionReason());
            return ResponseEntity.ok(requestRepository.save(r));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/requests/{id}/status")
    public ResponseEntity<VisitorRequest> updateRequestStatus(@PathVariable Long id, @RequestParam String status, @RequestParam(required = false) String reason) {
        return requestRepository.findById(id).map(r -> {
            r.setStatus(status);
            if (reason != null) r.setRejectionReason(reason);
            return ResponseEntity.ok(requestRepository.save(r));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/requests/{id}")
    public ResponseEntity<Void> deleteRequest(@PathVariable Long id) {
        if (!requestRepository.existsById(id)) return ResponseEntity.notFound().build();
        requestRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 3. Appointments ---
    @GetMapping("/appointments")
    public List<VisitorAppointment> getAllAppointments() {
        return appointmentRepository.findAll();
    }

    @PostMapping("/appointments")
    public ResponseEntity<VisitorAppointment> createAppointment(@RequestBody VisitorAppointment apt) {
        if (apt.getAptCode() == null || apt.getAptCode().isEmpty()) {
            apt.setAptCode("APT-" + (System.currentTimeMillis() % 100000));
        }
        if (apt.getStatus() == null) apt.setStatus("Scheduled");
        return ResponseEntity.ok(appointmentRepository.save(apt));
    }

    @PutMapping("/appointments/{id}")
    public ResponseEntity<VisitorAppointment> updateAppointment(@PathVariable Long id, @RequestBody VisitorAppointment updated) {
        return appointmentRepository.findById(id).map(a -> {
            a.setVisitorName(updated.getVisitorName());
            a.setOrganization(updated.getOrganization());
            a.setPhone(updated.getPhone());
            a.setHostEmployee(updated.getHostEmployee());
            a.setPlantLocation(updated.getPlantLocation());
            a.setScheduledDate(updated.getScheduledDate());
            a.setScheduledTime(updated.getScheduledTime());
            a.setVenue(updated.getVenue());
            a.setType(updated.getType());
            a.setStatus(updated.getStatus());
            a.setSendNotification(updated.getSendNotification());
            a.setRemarks(updated.getRemarks());
            return ResponseEntity.ok(appointmentRepository.save(a));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/appointments/{id}")
    public ResponseEntity<Void> deleteAppointment(@PathVariable Long id) {
        if (!appointmentRepository.existsById(id)) return ResponseEntity.notFound().build();
        appointmentRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 4. Vehicles ---
    @GetMapping("/vehicles")
    public List<VisitorVehicle> getAllVehicles() {
        return vehicleRepository.findAll();
    }

    @PostMapping("/vehicles")
    public ResponseEntity<VisitorVehicle> createVehicle(@RequestBody VisitorVehicle v) {
        if (v.getStatus() == null) v.setStatus("Inside");
        if (v.getGateInTime() == null) v.setGateInTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("hh:mm a")));
        return ResponseEntity.ok(vehicleRepository.save(v));
    }

    @PutMapping("/vehicles/{id}")
    public ResponseEntity<VisitorVehicle> updateVehicle(@PathVariable Long id, @RequestBody VisitorVehicle updated) {
        return vehicleRepository.findById(id).map(v -> {
            v.setVehicleNo(updated.getVehicleNo());
            v.setType(updated.getType());
            v.setDriverName(updated.getDriverName());
            v.setPhone(updated.getPhone());
            v.setLicenseNo(updated.getLicenseNo());
            v.setPurpose(updated.getPurpose());
            v.setConsignmentWeight(updated.getConsignmentWeight());
            v.setSparkArrestorVerified(updated.getSparkArrestorVerified());
            v.setGateInTime(updated.getGateInTime());
            v.setGateOutTime(updated.getGateOutTime());
            v.setStatus(updated.getStatus());
            v.setParkingBay(updated.getParkingBay());
            v.setWeighbridgeSlipNo(updated.getWeighbridgeSlipNo());
            return ResponseEntity.ok(vehicleRepository.save(v));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/vehicles/{id}")
    public ResponseEntity<Void> deleteVehicle(@PathVariable Long id) {
        if (!vehicleRepository.existsById(id)) return ResponseEntity.notFound().build();
        vehicleRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 5. Material Inward ---
    @GetMapping("/material-inward")
    public List<VisitorMaterialInward> getAllMaterialInward() {
        return materialInwardRepository.findAll();
    }

    @PostMapping("/material-inward")
    public ResponseEntity<VisitorMaterialInward> createMaterialInward(@RequestBody VisitorMaterialInward mat) {
        if (mat.getInwardCode() == null || mat.getInwardCode().isEmpty()) {
            mat.setInwardCode("MIN-" + (System.currentTimeMillis() % 100000));
        }
        if (mat.getStatus() == null) mat.setStatus("Received");
        return ResponseEntity.ok(materialInwardRepository.save(mat));
    }

    @PutMapping("/material-inward/{id}")
    public ResponseEntity<VisitorMaterialInward> updateMaterialInward(@PathVariable Long id, @RequestBody VisitorMaterialInward updated) {
        return materialInwardRepository.findById(id).map(m -> {
            m.setDate(updated.getDate());
            m.setTime(updated.getTime());
            m.setItemDescription(updated.getItemDescription());
            m.setQuantity(updated.getQuantity());
            m.setPoChallanNo(updated.getPoChallanNo());
            m.setVendorName(updated.getVendorName());
            m.setDeliveryCarrier(updated.getDeliveryCarrier());
            m.setReceivingDepartment(updated.getReceivingDepartment());
            m.setType(updated.getType());
            m.setInspectorName(updated.getInspectorName());
            m.setStatus(updated.getStatus());
            return ResponseEntity.ok(materialInwardRepository.save(m));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/material-inward/{id}")
    public ResponseEntity<Void> deleteMaterialInward(@PathVariable Long id) {
        if (!materialInwardRepository.existsById(id)) return ResponseEntity.notFound().build();
        materialInwardRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 6. Material Outward ---
    @GetMapping("/material-outward")
    public List<VisitorMaterialOutward> getAllMaterialOutward() {
        return materialOutwardRepository.findAll();
    }

    @PostMapping("/material-outward")
    public ResponseEntity<VisitorMaterialOutward> createMaterialOutward(@RequestBody VisitorMaterialOutward mat) {
        if (mat.getOutwardCode() == null || mat.getOutwardCode().isEmpty()) {
            mat.setOutwardCode("MOUT-" + (System.currentTimeMillis() % 100000));
        }
        if (mat.getStatus() == null) mat.setStatus("Dispatched");
        return ResponseEntity.ok(materialOutwardRepository.save(mat));
    }

    @PutMapping("/material-outward/{id}")
    public ResponseEntity<VisitorMaterialOutward> updateMaterialOutward(@PathVariable Long id, @RequestBody VisitorMaterialOutward updated) {
        return materialOutwardRepository.findById(id).map(m -> {
            m.setDate(updated.getDate());
            m.setTime(updated.getTime());
            m.setItemDescription(updated.getItemDescription());
            m.setQuantity(updated.getQuantity());
            m.setDispatchChallanNo(updated.getDispatchChallanNo());
            m.setRecipient(updated.getRecipient());
            m.setVehicleNo(updated.getVehicleNo());
            m.setType(updated.getType());
            m.setAuthorizedBy(updated.getAuthorizedBy());
            m.setGateSignOffTime(updated.getGateSignOffTime());
            m.setStatus(updated.getStatus());
            return ResponseEntity.ok(materialOutwardRepository.save(m));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/material-outward/{id}")
    public ResponseEntity<Void> deleteMaterialOutward(@PathVariable Long id) {
        if (!materialOutwardRepository.existsById(id)) return ResponseEntity.notFound().build();
        materialOutwardRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 7. Safety Clearances ---
    @GetMapping("/safety-clearances")
    public List<VisitorSafetyClearance> getAllSafetyClearances() {
        return safetyClearanceRepository.findAll();
    }

    @PostMapping("/safety-clearances")
    public ResponseEntity<VisitorSafetyClearance> createSafetyClearance(@RequestBody VisitorSafetyClearance sc) {
        if (sc.getClearanceCode() == null || sc.getClearanceCode().isEmpty()) {
            sc.setClearanceCode("SAF-" + (System.currentTimeMillis() % 100000));
        }
        if (sc.getStatus() == null) sc.setStatus("Cleared");
        return ResponseEntity.ok(safetyClearanceRepository.save(sc));
    }

    @PutMapping("/safety-clearances/{id}")
    public ResponseEntity<VisitorSafetyClearance> updateSafetyClearance(@PathVariable Long id, @RequestBody VisitorSafetyClearance updated) {
        return safetyClearanceRepository.findById(id).map(s -> {
            s.setVisitorName(updated.getVisitorName());
            s.setOrganization(updated.getOrganization());
            s.setInductedBy(updated.getInductedBy());
            s.setInductionDate(updated.getInductionDate());
            s.setInductionTime(updated.getInductionTime());
            s.setHazardBriefingCompleted(updated.getHazardBriefingCompleted());
            s.setPpeChecklist(updated.getPpeChecklist());
            s.setEmergencyBriefed(updated.getEmergencyBriefed());
            s.setStatus(updated.getStatus());
            return ResponseEntity.ok(safetyClearanceRepository.save(s));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/safety-clearances/{id}")
    public ResponseEntity<Void> deleteSafetyClearance(@PathVariable Long id) {
        if (!safetyClearanceRepository.existsById(id)) return ResponseEntity.notFound().build();
        safetyClearanceRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- 8. Plant Visitor Configurations ---
    @GetMapping("/config")
    public ResponseEntity<VisitorConfig> getConfig() {
        List<VisitorConfig> configs = configRepository.findAll();
        if (configs.isEmpty()) {
            VisitorConfig c = new VisitorConfig();
            c.setPlantName("BioNova Central Biogas Plant #1 (Hyderabad East)");
            c.setMaxPassDurationHours(8);
            c.setGateOpeningTime("06:00 AM");
            c.setGateClosingTime("10:00 PM");
            c.setAutoOverdueThresholdMinutes(30);
            c.setRequireGovtId(true);
            c.setRequireSafetyInduction(true);
            c.setRequireHostApprovalForVendors(true);
            return ResponseEntity.ok(configRepository.save(c));
        }
        return ResponseEntity.ok(configs.get(0));
    }

    @PutMapping("/config")
    public ResponseEntity<VisitorConfig> updateConfig(@RequestBody VisitorConfig updated) {
        List<VisitorConfig> configs = configRepository.findAll();
        VisitorConfig c = configs.isEmpty() ? new VisitorConfig() : configs.get(0);
        c.setPlantName(updated.getPlantName());
        c.setMaxPassDurationHours(updated.getMaxPassDurationHours());
        c.setGateOpeningTime(updated.getGateOpeningTime());
        c.setGateClosingTime(updated.getGateClosingTime());
        c.setAutoOverdueThresholdMinutes(updated.getAutoOverdueThresholdMinutes());
        c.setRequireGovtId(updated.getRequireGovtId());
        c.setRequireSafetyInduction(updated.getRequireSafetyInduction());
        c.setRequireHostApprovalForVendors(updated.getRequireHostApprovalForVendors());
        c.setBlacklistedVisitors(updated.getBlacklistedVisitors());
        return ResponseEntity.ok(configRepository.save(c));
    }
}
