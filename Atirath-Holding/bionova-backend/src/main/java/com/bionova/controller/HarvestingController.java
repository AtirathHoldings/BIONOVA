package com.bionova.controller;

import com.bionova.entity.harvesting.HarvestBatch;
import com.bionova.repository.harvesting.HarvestBatchRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/harvesting")
public class HarvestingController {

    @Autowired
    private HarvestBatchRepository harvestBatchRepository;

    @GetMapping("/batches")
    public List<HarvestBatch> getBatches() {
        return harvestBatchRepository.findAll();
    }

    @PostMapping("/batches")
    public ResponseEntity<HarvestBatch> createBatch(@RequestBody HarvestBatch batch) {
        if (batch.getId() == null || batch.getId().trim().isEmpty()) {
            batch.setId("HARV-2026-" + (System.currentTimeMillis() % 10000));
        }
        return ResponseEntity.ok(harvestBatchRepository.save(batch));
    }

    @PutMapping("/batches/{id}")
    public ResponseEntity<HarvestBatch> updateBatch(@PathVariable String id, @RequestBody HarvestBatch updated) {
        return harvestBatchRepository.findById(id).map(existing -> {
            existing.setParcelId(updated.getParcelId());
            existing.setFarmName(updated.getFarmName());
            existing.setCrop(updated.getCrop());
            existing.setAcreage(updated.getAcreage());
            existing.setCutNumber(updated.getCutNumber());
            existing.setPlannedHarvestDate(updated.getPlannedHarvestDate());
            existing.setEstimatedYieldMT(updated.getEstimatedYieldMT());
            existing.setActualHarvestedMT(updated.getActualHarvestedMT());
            existing.setMoisturePercent(updated.getMoisturePercent());
            existing.setTargetMoisture(updated.getTargetMoisture());
            existing.setAssignedFleet(updated.getAssignedFleet());
            existing.setSilageBunker(updated.getSilageBunker());
            existing.setStatus(updated.getStatus());
            existing.setSupervisor(updated.getSupervisor());
            existing.setNotes(updated.getNotes());
            return ResponseEntity.ok(harvestBatchRepository.save(existing));
        }).orElseGet(() -> {
            updated.setId(id);
            return ResponseEntity.ok(harvestBatchRepository.save(updated));
        });
    }

    @DeleteMapping("/batches/{id}")
    public ResponseEntity<Void> deleteBatch(@PathVariable String id) {
        if (!harvestBatchRepository.existsById(id)) return ResponseEntity.notFound().build();
        harvestBatchRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
