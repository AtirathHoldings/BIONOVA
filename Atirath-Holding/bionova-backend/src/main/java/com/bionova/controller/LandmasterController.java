package com.bionova.controller;

import com.bionova.entity.Landmaster;
import com.bionova.repository.LandmasterRepository;
import com.bionova.repository.PlantRepository;
import com.bionova.repository.StateRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class LandmasterController {

    @Autowired
    private LandmasterRepository landmasterRepository;

    @Autowired
    private StateRepository stateRepository;

    @Autowired
    private PlantRepository plantRepository;

    @GetMapping("/lands")
    public List<Landmaster> getLandmasters() {
        return landmasterRepository.findAll();
    }

    @PostMapping("/lands")
    public ResponseEntity<?> saveLandmaster(@RequestBody Landmaster land) {

        // Duplicate Land Code
        if (land.getLandCd() != null &&
                landmasterRepository.existsByLandCd(land.getLandCd())) {

            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Land Code already exists."));
        }

        // Plant Validation
        if (land.getPltId() != null &&
                !plantRepository.existsById(land.getPltId())) {

            return ResponseEntity.badRequest()
                    .body(Map.of("message", "Invalid Plant."));
        }

        // State Validation
        if (land.getStId() != null) {

            stateRepository.findById(land.getStId())
                    .ifPresent(state -> land.setZnNm(state.getZnNm()));
        }

        if (land.getZnNm() == null || land.getZnNm().trim().isEmpty()) {
            land.setZnNm("SOUTH");
        }

        // Lease Date Validation
        if (land.getLeaseDt() != null &&
                land.getLeaseEndDt() != null &&
                land.getLeaseEndDt().isBefore(land.getLeaseDt())) {

            return ResponseEntity.badRequest()
                    .body(Map.of("message",
                            "Lease End Date cannot be before Lease Start Date."));
        }

        Landmaster saved = landmasterRepository.save(land);

        return ResponseEntity.ok(saved);
    }

    @PutMapping("/lands/{id}")
    public ResponseEntity<?> updateLand(
            @PathVariable Long id,
            @RequestBody Landmaster details) {

        Landmaster land = landmasterRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Land not found"));

        // Duplicate Land Code
        if (details.getLandCd() != null &&
                landmasterRepository.existsByLandCdAndLandIdNot(
                        details.getLandCd(),
                        id)) {

            return ResponseEntity.badRequest()
                    .body(Map.of("message",
                            "Land Code already exists."));
        }

        // Plant Validation
        if (details.getPltId() != null &&
                !plantRepository.existsById(details.getPltId())) {

            return ResponseEntity.badRequest()
                    .body(Map.of("message",
                            "Invalid Plant."));
        }

        land.setLandCd(details.getLandCd());
        land.setPltId(details.getPltId());
        land.setSurveyNo(details.getSurveyNo());
        land.setLandOwners(details.getLandOwners());
        land.setMobNum(details.getMobNum());
        land.setLandSize(details.getLandSize());
        land.setAllotedFor(details.getAllotedFor());

        land.setLeaseDt(details.getLeaseDt());
        land.setLeaseEndDt(details.getLeaseEndDt());

        land.setVlg(details.getVlg());
        land.setMdl(details.getMdl());
        land.setDist(details.getDist());

        land.setStId(details.getStId());

        if (details.getStId() != null) {

            stateRepository.findById(details.getStId())
                    .ifPresent(state ->
                            land.setZnNm(state.getZnNm()));

        }

        if (land.getZnNm() == null || land.getZnNm().trim().isEmpty()) {
            land.setZnNm("SOUTH");
        }

        land.setPin(details.getPin());
        land.setLat(details.getLat());
        land.setLongt(details.getLongt());

        // Store Supabase URL
        land.setLogo(details.getLogo());

        land.setSts(details.getSts());

        // Lease Validation
        if (land.getLeaseDt() != null &&
                land.getLeaseEndDt() != null &&
                land.getLeaseEndDt().isBefore(land.getLeaseDt())) {

            return ResponseEntity.badRequest()
                    .body(Map.of("message",
                            "Lease End Date cannot be before Lease Start Date."));
        }

        Landmaster updated = landmasterRepository.save(land);

        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/lands/{id}")
    public ResponseEntity<Void> deleteLandmaster(@PathVariable Long id) {

        landmasterRepository.deleteById(id);

        return ResponseEntity.ok().build();
    }
}