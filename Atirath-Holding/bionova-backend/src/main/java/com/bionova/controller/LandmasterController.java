package com.bionova.controller;

import com.bionova.entity.Landmaster;
import com.bionova.repository.LandmasterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class LandmasterController {

    @Autowired
    private LandmasterRepository LandmasterRepository;

    @GetMapping("/lands")
    public List<Landmaster> getLandmasters() {
        return LandmasterRepository.findAll();
    }

    @PostMapping("/lands")
    public ResponseEntity<Landmaster> saveLandmaster(@RequestBody Landmaster allocation) {
        Landmaster saved = LandmasterRepository.save(allocation);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/lands/{id}")
    public ResponseEntity<Void> deleteLandmaster(@PathVariable Long id) {
        LandmasterRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
