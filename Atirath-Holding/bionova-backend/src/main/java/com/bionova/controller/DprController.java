package com.bionova.controller;

import com.bionova.entity.dpr.DprRecord;
import com.bionova.repository.dpr.DprRecordRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/dpr")
public class DprController {

    @Autowired
    private DprRecordRepository dprRepository;

    @GetMapping
    public List<DprRecord> getAll() {
        return dprRepository.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<DprRecord> getById(@PathVariable String id) {
        return dprRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<DprRecord> create(@RequestBody DprRecord record) {
        if (record.getId() == null || record.getId().trim().isEmpty()) {
            record.setId("DPR-" + System.currentTimeMillis());
        }
        return ResponseEntity.ok(dprRepository.save(record));
    }

    @PutMapping("/{id}")
    public ResponseEntity<DprRecord> update(@PathVariable String id, @RequestBody DprRecord updated) {
        return dprRepository.findById(id).map(existing -> {
            existing.setDate(updated.getDate());
            existing.setShift(updated.getShift());
            existing.setProjectName(updated.getProjectName());
            existing.setContractor(updated.getContractor());
            existing.setEngineer(updated.getEngineer());
            existing.setWeather(updated.getWeather());
            existing.setWorkableDay(updated.getWorkableDay());
            existing.setStatus(updated.getStatus());
            existing.setSubmittedAt(updated.getSubmittedAt());
            existing.setApprovedBy(updated.getApprovedBy());
            existing.setApprovedAt(updated.getApprovedAt());
            existing.setPmRemarks(updated.getPmRemarks());
            existing.setTomorrowPlan(updated.getTomorrowPlan());
            if (updated.getActivities() != null) existing.setActivities(updated.getActivities());
            if (updated.getManpower() != null) existing.setManpower(updated.getManpower());
            if (updated.getEquipment() != null) existing.setEquipment(updated.getEquipment());
            if (updated.getMaterials() != null) existing.setMaterials(updated.getMaterials());
            if (updated.getHse() != null) existing.setHse(updated.getHse());
            if (updated.getPhotos() != null) existing.setPhotos(updated.getPhotos());
            if (updated.getAuditTrail() != null) existing.setAuditTrail(updated.getAuditTrail());
            return ResponseEntity.ok(dprRepository.save(existing));
        }).orElseGet(() -> {
            updated.setId(id);
            return ResponseEntity.ok(dprRepository.save(updated));
        });
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<DprRecord> approve(@PathVariable String id, @RequestBody(required = false) Map<String, Object> body) {
        String remarks = body != null && body.containsKey("remarks") ? (String) body.get("remarks") : "";
        String actorName = body != null && body.containsKey("actorName") ? (String) body.get("actorName") : "Project Manager";
        String nowStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));

        return dprRepository.findById(id).map(existing -> {
            existing.setStatus("Approved");
            existing.setApprovedBy(actorName);
            existing.setApprovedAt(nowStr);
            if (remarks != null && !remarks.isEmpty()) existing.setPmRemarks(remarks);
            return ResponseEntity.ok(dprRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/{id}/return")
    public ResponseEntity<DprRecord> returnDpr(@PathVariable String id, @RequestBody(required = false) Map<String, Object> body) {
        String remarks = body != null && body.containsKey("remarks") ? (String) body.get("remarks") : "";
        String actorName = body != null && body.containsKey("actorName") ? (String) body.get("actorName") : "Project Manager";

        return dprRepository.findById(id).map(existing -> {
            existing.setStatus("Returned");
            if (remarks != null && !remarks.isEmpty()) existing.setPmRemarks(remarks);
            return ResponseEntity.ok(dprRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        if (!dprRepository.existsById(id)) return ResponseEntity.notFound().build();
        dprRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
