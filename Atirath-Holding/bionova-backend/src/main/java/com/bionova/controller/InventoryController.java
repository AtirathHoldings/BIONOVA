package com.bionova.controller;

import com.bionova.entity.inventory.*;
import com.bionova.repository.inventory.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/inventory")
public class InventoryController {

    @Autowired
    private InventoryItemRepository itemRepository;

    @Autowired
    private InventoryCivilBomRepository civilBomRepository;

    @Autowired
    private InventoryFastenerRepository fastenerRepository;

    @Autowired
    private InventoryPipingRepository pipingRepository;

    @Autowired
    private InventoryWarrantyRepository warrantyRepository;

    @Autowired
    private InventoryAlertRepository alertRepository;

    @Autowired
    private InventoryWeighbridgeRepository weighbridgeRepository;

    @Autowired
    private InventoryVendorRepository vendorRepository;

    // --- 1. Agri & Core Stock Items ---
    @GetMapping("/items")
    public List<InventoryItem> getAllItems() {
        return itemRepository.findAll();
    }

    @PostMapping("/items")
    public ResponseEntity<InventoryItem> createItem(@RequestBody InventoryItem item) {
        return ResponseEntity.ok(itemRepository.save(item));
    }

    @PutMapping("/items/{id}")
    public ResponseEntity<InventoryItem> updateItem(@PathVariable Long id, @RequestBody InventoryItem item) {
        return itemRepository.findById(id).map(existing -> {
            item.setId(id);
            return ResponseEntity.ok(itemRepository.save(item));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/items/{id}")
    public ResponseEntity<Void> deleteItem(@PathVariable Long id) {
        if (!itemRepository.existsById(id)) return ResponseEntity.notFound().build();
        itemRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // --- 2. Civil Materials BOM ---
    @GetMapping("/civil-bom")
    public List<InventoryCivilBom> getAllCivilBom() {
        return civilBomRepository.findAll();
    }

    @PostMapping("/civil-bom")
    public ResponseEntity<InventoryCivilBom> createCivilBom(@RequestBody InventoryCivilBom bom) {
        return ResponseEntity.ok(civilBomRepository.save(bom));
    }

    @PutMapping("/civil-bom/{id}")
    public ResponseEntity<InventoryCivilBom> updateCivilBom(@PathVariable Long id, @RequestBody InventoryCivilBom bom) {
        return civilBomRepository.findById(id).map(existing -> {
            bom.setId(id);
            return ResponseEntity.ok(civilBomRepository.save(bom));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/civil-bom/{id}")
    public ResponseEntity<Void> deleteCivilBom(@PathVariable Long id) {
        if (!civilBomRepository.existsById(id)) return ResponseEntity.notFound().build();
        civilBomRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // --- 3. Fasteners & Hardware ---
    @GetMapping("/fasteners")
    public List<InventoryFastener> getAllFasteners() {
        return fastenerRepository.findAll();
    }

    @PostMapping("/fasteners")
    public ResponseEntity<InventoryFastener> createFastener(@RequestBody InventoryFastener fastener) {
        return ResponseEntity.ok(fastenerRepository.save(fastener));
    }

    @PutMapping("/fasteners/{id}")
    public ResponseEntity<InventoryFastener> updateFastener(@PathVariable Long id, @RequestBody InventoryFastener fastener) {
        return fastenerRepository.findById(id).map(existing -> {
            fastener.setId(id);
            return ResponseEntity.ok(fastenerRepository.save(fastener));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/fasteners/{id}")
    public ResponseEntity<Void> deleteFastener(@PathVariable Long id) {
        if (!fastenerRepository.existsById(id)) return ResponseEntity.notFound().build();
        fastenerRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // --- 4. Piping & Instrumentation ---
    @GetMapping("/piping")
    public List<InventoryPiping> getAllPiping() {
        return pipingRepository.findAll();
    }

    @PostMapping("/piping")
    public ResponseEntity<InventoryPiping> createPiping(@RequestBody InventoryPiping piping) {
        return ResponseEntity.ok(pipingRepository.save(piping));
    }

    @PutMapping("/piping/{id}")
    public ResponseEntity<InventoryPiping> updatePiping(@PathVariable Long id, @RequestBody InventoryPiping piping) {
        return pipingRepository.findById(id).map(existing -> {
            piping.setId(id);
            return ResponseEntity.ok(pipingRepository.save(piping));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/piping/{id}")
    public ResponseEntity<Void> deletePiping(@PathVariable Long id) {
        if (!pipingRepository.existsById(id)) return ResponseEntity.notFound().build();
        pipingRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // --- 5. Equipment Warranties ---
    @GetMapping("/warranties")
    public List<InventoryWarranty> getAllWarranties() {
        return warrantyRepository.findAll();
    }

    @PostMapping("/warranties")
    public ResponseEntity<InventoryWarranty> createWarranty(@RequestBody InventoryWarranty warranty) {
        return ResponseEntity.ok(warrantyRepository.save(warranty));
    }

    @PutMapping("/warranties/{id}")
    public ResponseEntity<InventoryWarranty> updateWarranty(@PathVariable Long id, @RequestBody InventoryWarranty warranty) {
        return warrantyRepository.findById(id).map(existing -> {
            warranty.setId(id);
            return ResponseEntity.ok(warrantyRepository.save(warranty));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/warranties/{id}")
    public ResponseEntity<Void> deleteWarranty(@PathVariable Long id) {
        if (!warrantyRepository.existsById(id)) return ResponseEntity.notFound().build();
        warrantyRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // --- 6. Stock Expiry & Low Stock Alerts ---
    @GetMapping("/alerts")
    public List<InventoryAlert> getAllAlerts() {
        return alertRepository.findAll();
    }

    @PostMapping("/alerts")
    public ResponseEntity<InventoryAlert> createAlert(@RequestBody InventoryAlert alert) {
        return ResponseEntity.ok(alertRepository.save(alert));
    }

    @DeleteMapping("/alerts/{id}")
    public ResponseEntity<Void> deleteAlert(@PathVariable Long id) {
        if (!alertRepository.existsById(id)) return ResponseEntity.notFound().build();
        alertRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // --- 7. Warehouse & Weighbridge Live Logs ---
    @GetMapping("/weighbridge")
    public List<InventoryWeighbridge> getAllWeighbridge() {
        return weighbridgeRepository.findAll();
    }

    @PostMapping("/weighbridge")
    public ResponseEntity<InventoryWeighbridge> createWeighbridge(@RequestBody InventoryWeighbridge wb) {
        return ResponseEntity.ok(weighbridgeRepository.save(wb));
    }

    @PutMapping("/weighbridge/{id}")
    public ResponseEntity<InventoryWeighbridge> updateWeighbridge(@PathVariable Long id, @RequestBody InventoryWeighbridge wb) {
        return weighbridgeRepository.findById(id).map(existing -> {
            wb.setId(id);
            return ResponseEntity.ok(weighbridgeRepository.save(wb));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/weighbridge/{id}")
    public ResponseEntity<Void> deleteWeighbridge(@PathVariable Long id) {
        if (!weighbridgeRepository.existsById(id)) return ResponseEntity.notFound().build();
        weighbridgeRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }

    // --- 8. Multi-Tier Vendors ---
    @GetMapping("/vendors")
    public List<InventoryVendor> getAllVendors() {
        return vendorRepository.findAll();
    }

    @PostMapping("/vendors")
    public ResponseEntity<InventoryVendor> createVendor(@RequestBody InventoryVendor vendor) {
        return ResponseEntity.ok(vendorRepository.save(vendor));
    }

    @PutMapping("/vendors/{id}")
    public ResponseEntity<InventoryVendor> updateVendor(@PathVariable Long id, @RequestBody InventoryVendor vendor) {
        return vendorRepository.findById(id).map(existing -> {
            vendor.setId(id);
            return ResponseEntity.ok(vendorRepository.save(vendor));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/vendors/{id}")
    public ResponseEntity<Void> deleteVendor(@PathVariable Long id) {
        if (!vendorRepository.existsById(id)) return ResponseEntity.notFound().build();
        vendorRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}

