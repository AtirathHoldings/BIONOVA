package com.bionova.controller;

import com.bionova.entity.ReviewerMaster;
import com.bionova.repository.ReviewerMasterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reviewers")
public class ReviewerMasterController {

    @Autowired
    private ReviewerMasterRepository reviewerRepo;

    @GetMapping
    public List<ReviewerMaster> getAll() {
        return reviewerRepo.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ReviewerMaster> getById(@PathVariable Integer id) {
        return reviewerRepo.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<ReviewerMaster> create(@RequestBody ReviewerMaster reviewer) {
        return ResponseEntity.ok(reviewerRepo.save(reviewer));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ReviewerMaster> update(@PathVariable Integer id,
                                                  @RequestBody ReviewerMaster details) {
        ReviewerMaster reviewer = reviewerRepo.findById(id)
                .orElseThrow(() -> new RuntimeException("Reviewer not found: " + id));
        reviewer.setRNm(details.getRNm());
        return ResponseEntity.ok(reviewerRepo.save(reviewer));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        reviewerRepo.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
