package com.bionova.controller;

import com.bionova.entity.dispatchlogistics.*;
import com.bionova.repository.dispatchlogistics.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/dispatch-logistics")
public class DispatchLogisticsController {

    @Autowired
    private VehicleTripSheetRepository tripSheetRepository;

    @Autowired
    private FleetDriverRepository driverRepository;

    @Autowired
    private LogisticsWeighbridgeSlipRepository weighbridgeSlipRepository;

    @Autowired
    private TransitTemperatureLogRepository temperatureLogRepository;

    // --- Trip Sheets ---
    @GetMapping("/trip-sheets")
    public List<VehicleTripSheet> getTripSheets() {
        return tripSheetRepository.findAll();
    }

    @PostMapping("/trip-sheets")
    public ResponseEntity<VehicleTripSheet> createTripSheet(@RequestBody VehicleTripSheet tripSheet) {
        tripSheet.setId(null);
        return ResponseEntity.ok(tripSheetRepository.save(tripSheet));
    }

    @PutMapping("/trip-sheets/{id}")
    public ResponseEntity<VehicleTripSheet> updateTripSheet(@PathVariable Long id, @RequestBody VehicleTripSheet updated) {
        return tripSheetRepository.findById(id).map(existing -> {
            existing.setTripNumber(updated.getTripNumber());
            existing.setOrigin(updated.getOrigin());
            existing.setDestination(updated.getDestination());
            existing.setAssignedVehicle(updated.getAssignedVehicle());
            existing.setAssignedDriver(updated.getAssignedDriver());
            existing.setCargoCategory(updated.getCargoCategory());
            existing.setDispatchQtyMT(updated.getDispatchQtyMT());
            existing.setDispatchDateTime(updated.getDispatchDateTime());
            existing.setStatus(updated.getStatus());
            return ResponseEntity.ok(tripSheetRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/trip-sheets/{id}")
    public ResponseEntity<Void> deleteTripSheet(@PathVariable Long id) {
        if (!tripSheetRepository.existsById(id)) return ResponseEntity.notFound().build();
        tripSheetRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Drivers ---
    @GetMapping("/drivers")
    public List<FleetDriver> getDrivers() {
        return driverRepository.findAll();
    }

    @PostMapping("/drivers")
    public ResponseEntity<FleetDriver> createDriver(@RequestBody FleetDriver driver) {
        driver.setId(null);
        return ResponseEntity.ok(driverRepository.save(driver));
    }

    @PutMapping("/drivers/{id}")
    public ResponseEntity<FleetDriver> updateDriver(@PathVariable Long id, @RequestBody FleetDriver updated) {
        return driverRepository.findById(id).map(existing -> {
            existing.setName(updated.getName());
            existing.setPhone(updated.getPhone());
            existing.setLicenseNumber(updated.getLicenseNumber());
            existing.setLicenseExpiry(updated.getLicenseExpiry());
            existing.setHazmatCertified(updated.getHazmatCertified());
            existing.setAssignedVehicle(updated.getAssignedVehicle());
            existing.setDutyStatus(updated.getDutyStatus());
            return ResponseEntity.ok(driverRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/drivers/{id}")
    public ResponseEntity<Void> deleteDriver(@PathVariable Long id) {
        if (!driverRepository.existsById(id)) return ResponseEntity.notFound().build();
        driverRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Weighbridge Slips ---
    @GetMapping("/weighbridge-slips")
    public List<LogisticsWeighbridgeSlip> getWeighbridgeSlips() {
        return weighbridgeSlipRepository.findAll();
    }

    @PostMapping("/weighbridge-slips")
    public ResponseEntity<LogisticsWeighbridgeSlip> createWeighbridgeSlip(@RequestBody LogisticsWeighbridgeSlip slip) {
        slip.setId(null);
        return ResponseEntity.ok(weighbridgeSlipRepository.save(slip));
    }

    @PutMapping("/weighbridge-slips/{id}")
    public ResponseEntity<LogisticsWeighbridgeSlip> updateWeighbridgeSlip(@PathVariable Long id, @RequestBody LogisticsWeighbridgeSlip updated) {
        return weighbridgeSlipRepository.findById(id).map(existing -> {
            existing.setSlipNumber(updated.getSlipNumber());
            existing.setTripNumber(updated.getTripNumber());
            existing.setVehicleNo(updated.getVehicleNo());
            existing.setInboundGrossMT(updated.getInboundGrossMT());
            existing.setOutboundTareMT(updated.getOutboundTareMT());
            existing.setNetWeightMT(updated.getNetWeightMT());
            existing.setExpectedQtyMT(updated.getExpectedQtyMT());
            existing.setOperatorName(updated.getOperatorName());
            existing.setScaleTimestamp(updated.getScaleTimestamp());
            existing.setStatus(updated.getStatus());
            return ResponseEntity.ok(weighbridgeSlipRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/weighbridge-slips/{id}")
    public ResponseEntity<Void> deleteWeighbridgeSlip(@PathVariable Long id) {
        if (!weighbridgeSlipRepository.existsById(id)) return ResponseEntity.notFound().build();
        weighbridgeSlipRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // --- Temperature Logs ---
    @GetMapping("/temperature-logs")
    public List<TransitTemperatureLog> getTemperatureLogs() {
        return temperatureLogRepository.findAll();
    }

    @PostMapping("/temperature-logs")
    public ResponseEntity<TransitTemperatureLog> createTemperatureLog(@RequestBody TransitTemperatureLog log) {
        log.setId(null);
        return ResponseEntity.ok(temperatureLogRepository.save(log));
    }

    @PutMapping("/temperature-logs/{id}")
    public ResponseEntity<TransitTemperatureLog> updateTemperatureLog(@PathVariable Long id, @RequestBody TransitTemperatureLog updated) {
        return temperatureLogRepository.findById(id).map(existing -> {
            existing.setSensorTag(updated.getSensorTag());
            existing.setTripNumber(updated.getTripNumber());
            existing.setCargoType(updated.getCargoType());
            existing.setCurrentTempC(updated.getCurrentTempC());
            existing.setMinThresholdC(updated.getMinThresholdC());
            existing.setMaxThresholdC(updated.getMaxThresholdC());
            existing.setAmbientTempC(updated.getAmbientTempC());
            existing.setLogTimestamp(updated.getLogTimestamp());
            existing.setStatus(updated.getStatus());
            return ResponseEntity.ok(temperatureLogRepository.save(existing));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/temperature-logs/{id}")
    public ResponseEntity<Void> deleteTemperatureLog(@PathVariable Long id) {
        if (!temperatureLogRepository.existsById(id)) return ResponseEntity.notFound().build();
        temperatureLogRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
