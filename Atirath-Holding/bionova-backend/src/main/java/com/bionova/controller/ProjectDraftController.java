package com.bionova.controller;

import com.bionova.entity.ProjectDraft;
import com.bionova.repository.ProjectDraftRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.temporal.ChronoUnit;
import java.util.List;

@RestController
@RequestMapping("/api/project-drafts")
public class ProjectDraftController {

    @Autowired
    private ProjectDraftRepository projectDraftRepository;

    /** GET all drafts */
    @GetMapping
    public List<ProjectDraft> getAll() {
        return projectDraftRepository.findAll();
    }

    /** GET by ID */
    @GetMapping("/{id}")
    public ResponseEntity<ProjectDraft> getById(@PathVariable Long id) {
        return projectDraftRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /** GET drafts by company */
    @GetMapping("/by-company/{coyId}")
    public List<ProjectDraft> getByCompany(@PathVariable Integer coyId) {
        return projectDraftRepository.findByCoyId(coyId);
    }

    /** GET drafts by company + plant */
    @GetMapping("/by-company/{coyId}/plant/{pltId}")
    public List<ProjectDraft> getByCompanyAndPlant(
            @PathVariable Integer coyId,
            @PathVariable Integer pltId) {
        return projectDraftRepository.findByCoyIdAndPltId(coyId, pltId);
    }

    /** POST – create new draft (auto-computes no_of_days, sets status DRAFT) */
    @PostMapping
    public ResponseEntity<ProjectDraft> create(@RequestBody ProjectDraft draft) {
        draft.setPrjSts("DRAFT");

        // Auto-compute tentative days
        if (draft.getTentStDt() != null && draft.getTentEndDt() != null) {
            long days = ChronoUnit.DAYS.between(draft.getTentStDt(), draft.getTentEndDt());
            draft.setNoOfDays((int) days);
        }

        ProjectDraft saved = projectDraftRepository.save(draft);
        return ResponseEntity.ok(saved);
    }

    /** PUT – update draft */
    @PutMapping("/{id}")
    public ResponseEntity<ProjectDraft> update(
            @PathVariable Long id,
            @RequestBody ProjectDraft details) {

        ProjectDraft draft = projectDraftRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Draft not found: " + id));

        draft.setPrjCd(details.getPrjCd());
        draft.setPrjNm(details.getPrjNm());
        draft.setPrjDesc(details.getPrjDesc());
        draft.setDeptId(details.getDeptId());
        draft.setPrjPrty(details.getPrjPrty());
        draft.setTentStDt(details.getTentStDt());
        draft.setTentEndDt(details.getTentEndDt());
        draft.setCoyId(details.getCoyId());
        draft.setPltId(details.getPltId());
        draft.setPrjObjtv(details.getPrjObjtv());
        draft.setExpDlvbls(details.getExpDlvbls());
        draft.setLogo(details.getLogo());
        draft.setAddlRem(details.getAddlRem());

        // Recompute no_of_days
        if (draft.getTentStDt() != null && draft.getTentEndDt() != null) {
            long days = ChronoUnit.DAYS.between(draft.getTentStDt(), draft.getTentEndDt());
            draft.setNoOfDays((int) days);
        }

        return ResponseEntity.ok(projectDraftRepository.save(draft));
    }

    /** DELETE */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        projectDraftRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
