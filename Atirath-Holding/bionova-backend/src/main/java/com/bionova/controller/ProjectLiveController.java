package com.bionova.controller;

import com.bionova.entity.ProjectDraft;
import com.bionova.entity.ProjectLive;
import com.bionova.repository.ProjectDraftRepository;
import com.bionova.repository.ProjectLiveRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/project-live")
public class ProjectLiveController {

    @Autowired
    private ProjectLiveRepository projectLiveRepository;

    @Autowired
    private ProjectDraftRepository projectDraftRepository;

    /** GET all live projects */
    @GetMapping
    public List<ProjectLive> getAll() {
        return projectLiveRepository.findAll();
    }

    /** GET by ID */
    @GetMapping("/{id}")
    public ResponseEntity<ProjectLive> getById(@PathVariable Long id) {
        return projectLiveRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /** GET live projects by company */
    @GetMapping("/by-company/{coyId}")
    public List<ProjectLive> getByCompany(@PathVariable Integer coyId) {
        return projectLiveRepository.findByCoyId(coyId);
    }

    /** GET live projects by company + plant */
    @GetMapping("/by-company/{coyId}/plant/{pltId}")
    public List<ProjectLive> getByCompanyAndPlant(
            @PathVariable Integer coyId,
            @PathVariable Integer pltId) {
        return projectLiveRepository.findByCoyIdAndPltId(coyId, pltId);
    }

    /**
     * POST /api/project-live/promote/{drftPrjId}
     * Promotes a Draft project to Live.
     * Body: { "stDt": "2026-07-01", "prjSts": "LIVE" }
     */
    @PostMapping("/promote/{drftPrjId}")
    public ResponseEntity<?> promoteToLive(
            @PathVariable Integer drftPrjId,
            @RequestBody ProjectLive liveDetails) {

        // 1. Fetch draft
        ProjectDraft draft = projectDraftRepository.findById(drftPrjId.longValue())
                .orElse(null);
        if (draft == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Draft not found: " + drftPrjId));
        }

        // 2. Check if already promoted
        if (projectLiveRepository.findByDrftPrjId(drftPrjId).isPresent()) {
            return ResponseEntity.badRequest().body(Map.of("error", "This draft has already been promoted to Live."));
        }

        // 3. Copy draft data into live record
        ProjectLive live = new ProjectLive();
        live.setDrftPrjId(drftPrjId);
        live.setPrjCd(draft.getPrjCd());
        live.setPrjNm(draft.getPrjNm());
        live.setPrjDesc(draft.getPrjDesc());
        live.setDeptId(draft.getDeptId());
        live.setPrjPrty(draft.getPrjPrty());
        live.setCoyId(draft.getCoyId());
        live.setPltId(draft.getPltId());
        live.setPrjObjtv(draft.getPrjObjtv());
        live.setExpDlvbls(draft.getExpDlvbls());
        live.setLogo(draft.getLogo());
        live.setAddlRem(draft.getAddlRem());

        // 4. Apply live-specific fields from request body
        live.setPrjSts(liveDetails.getPrjSts() != null ? liveDetails.getPrjSts() : "LIVE");
        live.setStDt(liveDetails.getStDt() != null ? liveDetails.getStDt() : draft.getTentStDt());
        live.setEndDt(liveDetails.getEndDt() != null ? liveDetails.getEndDt() : draft.getTentEndDt());

        // 5. Compute no_of_days
        if (live.getStDt() != null && live.getEndDt() != null) {
            long days = ChronoUnit.DAYS.between(live.getStDt(), live.getEndDt());
            live.setNoOfDays((int) days);
        }

        ProjectLive saved = projectLiveRepository.save(live);
        return ResponseEntity.ok(saved);
    }

    /** PUT – update live project (status change: LIVE → HOLD / CLOSED etc.) */
    @PutMapping("/{id}")
    public ResponseEntity<ProjectLive> update(
            @PathVariable Long id,
            @RequestBody ProjectLive details) {

        ProjectLive live = projectLiveRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Live project not found: " + id));

        live.setPrjNm(details.getPrjNm());
        live.setPrjDesc(details.getPrjDesc());
        live.setDeptId(details.getDeptId());
        live.setPrjPrty(details.getPrjPrty());
        live.setPrjSts(details.getPrjSts());
        live.setStDt(details.getStDt());
        live.setEndDt(details.getEndDt());
        live.setCoyId(details.getCoyId());
        live.setPltId(details.getPltId());
        live.setPrjObjtv(details.getPrjObjtv());
        live.setExpDlvbls(details.getExpDlvbls());
        live.setLogo(details.getLogo());
        live.setAddlRem(details.getAddlRem());

        if (live.getStDt() != null && live.getEndDt() != null) {
            long days = ChronoUnit.DAYS.between(live.getStDt(), live.getEndDt());
            live.setNoOfDays((int) days);
        }

        return ResponseEntity.ok(projectLiveRepository.save(live));
    }

    /** DELETE */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        projectLiveRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
