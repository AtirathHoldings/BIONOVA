package com.bionova.controller;

import com.bionova.dto.inventory.SkuAllocateRequest;
import com.bionova.dto.inventory.SkuPreviewRequest;
import com.bionova.dto.inventory.SkuPreviewResponse;
import com.bionova.entity.inventory.SkuMaster;
import com.bionova.repository.inventory.SkuMasterRepository;
import com.bionova.service.inventory.SkuGenerationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/inventory/sku")
public class SkuController {

    @Autowired
    private SkuGenerationService skuService;

    @Autowired
    private SkuMasterRepository masterRepository;

    @GetMapping("/master-data")
    public ResponseEntity<Map<String, Map<String, List<SkuMaster>>>> getMasterData() {
        return ResponseEntity.ok(skuService.getMasterData());
    }

    @PostMapping("/preview")
    public ResponseEntity<SkuPreviewResponse> generatePreview(@RequestBody SkuPreviewRequest request) {
        return ResponseEntity.ok(skuService.generatePreview(request));
    }

    @PostMapping("/allocate")
    public ResponseEntity<Map<String, String>> allocateSku(@RequestBody SkuAllocateRequest request) {
        String sku = skuService.allocateNextSku(request);
        return ResponseEntity.ok(Map.of("sku", sku));
    }

    @PostMapping("/master-data")
    public ResponseEntity<SkuMaster> addMasterData(@RequestBody SkuMaster master) {
        master.setId(null);
        if (master.getIsActive() == null) master.setIsActive(true);
        return ResponseEntity.ok(masterRepository.save(master));
    }
}
