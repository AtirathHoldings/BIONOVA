package com.bionova.controller;

import com.bionova.entity.PlantMaster;
import com.bionova.repository.PlantRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class PlantController {

    @Autowired
    private PlantRepository plantRepository;

    @GetMapping("/plants")
    public List<PlantMaster> getPlants() {
        return plantRepository.findAll();
    }

    @GetMapping("/plants/by-company/{coyId}")
    public List<PlantMaster> getPlantsByCompany(@PathVariable Long coyId) {
        return plantRepository.findByCoyId(coyId);
    }

    @PostMapping("/plants")
    public ResponseEntity<PlantMaster> savePlant(@RequestBody PlantMaster plant) {
        if (plant.getPltCd() == null || plant.getPltCd().trim().isEmpty()) {
            plant.setPltCd("PLT-" + (int)(Math.random() * 900 + 100));
        }
        PlantMaster savedPlant = plantRepository.save(plant);
        return ResponseEntity.ok(savedPlant);
    }

    @PutMapping("/plants/{id}")
    public ResponseEntity<PlantMaster> updatePlant(@PathVariable Long id, @RequestBody PlantMaster details) {
        PlantMaster plant = plantRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Plant not found"));
        plant.setPltCd(details.getPltCd());
        plant.setCoyId(details.getCoyId());
        plant.setPltNm(details.getPltNm());
        plant.setCap(details.getCap());
        plant.setEmail(details.getEmail());
        plant.setAddr(details.getAddr());
        plant.setDist(details.getDist());
        plant.setStId(details.getStId());
        plant.setZnNm(details.getZnNm());
        plant.setPin(details.getPin());
        plant.setLat(details.getLat());
        plant.setLongt(details.getLongt());
        plant.setAddlRem(details.getAddlRem());
        plant.setSts(details.getSts());
        PlantMaster saved = plantRepository.save(plant);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/plants/{id}")
    public ResponseEntity<Void> deletePlant(@PathVariable("id") Long id) {
        plantRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}