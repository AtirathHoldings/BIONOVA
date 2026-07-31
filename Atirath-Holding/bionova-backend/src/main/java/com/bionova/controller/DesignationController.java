package com.bionova.controller;

import com.bionova.entity.DesignationMaster;
import com.bionova.repository.DesignationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class DesignationController {

    @Autowired
    private DesignationRepository designationRepository;

    @GetMapping("/designations")
    public List<DesignationMaster> getDesignations() {
        return designationRepository.findAll();
    }

    @PostMapping("/designations")
    public ResponseEntity<DesignationMaster> saveDesignation(@RequestBody DesignationMaster designation) {
        DesignationMaster saved = designationRepository.save(designation);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/designations/{id}")
    public ResponseEntity<DesignationMaster> updateDesignation(@PathVariable Integer id, @RequestBody DesignationMaster details) {
        DesignationMaster desig = designationRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Designation not found"));
        desig.setDesigCd(details.getDesigCd());
        desig.setDesigNm(details.getDesigNm());
        desig.setDesigDesc(details.getDesigDesc());
        DesignationMaster saved = designationRepository.save(desig);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/designations/{id}")
    public ResponseEntity<?> deleteDesignation(@PathVariable Integer id) {
        designationRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
