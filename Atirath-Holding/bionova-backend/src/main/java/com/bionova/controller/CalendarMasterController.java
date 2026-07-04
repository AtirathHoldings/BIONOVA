package com.bionova.controller;

import com.bionova.entity.CalendarMaster;
import com.bionova.repository.CalendarMasterRepository;
import com.bionova.service.CalendarService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/calendar")
public class CalendarMasterController {

    @Autowired
    private CalendarMasterRepository calendarMasterRepository;

    @Autowired
    private CalendarService calendarService;

    // ── GET endpoints ──────────────────────────────────────────────────────

    /** GET all holidays */
    @GetMapping
    public List<CalendarMaster> getAll() {
        return calendarMasterRepository.findAll();
    }

    /** GET holidays by company */
    @GetMapping("/by-company/{coyId}")
    public List<CalendarMaster> getByCompany(@PathVariable Integer coyId) {
        return calendarMasterRepository.findByCoyId(coyId);
    }

    /** GET holidays by company + plant */
    @GetMapping("/by-company/{coyId}/plant/{pltId}")
    public List<CalendarMaster> getByCompanyAndPlant(
            @PathVariable Integer coyId,
            @PathVariable Integer pltId) {
        return calendarMasterRepository.findByCoyIdAndPltId(coyId, pltId);
    }

    /** GET holidays by year */
    @GetMapping("/by-year/{year}")
    public List<CalendarMaster> getByYear(@PathVariable Integer year) {
        return calendarMasterRepository.findByCalYr(year);
    }

    /** GET holidays by company + year */
    @GetMapping("/by-company/{coyId}/year/{year}")
    public List<CalendarMaster> getByCompanyAndYear(
            @PathVariable Integer coyId,
            @PathVariable Integer year) {
        return calendarMasterRepository.findByCoyIdAndCalYr(coyId, year);
    }

    /**
     * GET working days preview:
     * Calculates working days between two dates considering holidays.
     *
     * Example: GET /api/calendar/working-days?startDate=2026-07-01&endDate=2026-07-31
     *           &excludeSat=true&excludeSun=true&includeMandatory=true&coyId=1&pltId=1
     */
    @GetMapping("/working-days")
    public ResponseEntity<Map<String, Object>> getWorkingDays(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "false") boolean excludeSat,
            @RequestParam(defaultValue = "true")  boolean excludeSun,
            @RequestParam(defaultValue = "true")  boolean includeMandatory,
            @RequestParam(required = false) Integer coyId,
            @RequestParam(required = false) Integer pltId) {

        CalendarService.HolidaySummary summary = calendarService.getHolidaySummary(
                startDate, endDate, excludeSat, excludeSun, includeMandatory, coyId, pltId);

        return ResponseEntity.ok(Map.of(
                "startDate",    startDate.toString(),
                "endDate",      endDate.toString(),
                "totalDays",    summary.totalDays(),
                "workingDays",  summary.workingDays(),
                "holidayDays",  summary.holidayDays(),
                "excludeSat",   excludeSat,
                "excludeSun",   excludeSun,
                "includeMandatoryHolidays", includeMandatory,
                "coyId",  coyId  != null ? coyId  : "ALL",
                "pltId",  pltId  != null ? pltId  : "ALL"
        ));
    }

    // ── POST / PUT / PATCH / DELETE ────────────────────────────────────────

    /** POST – add a holiday (auto-fills cal_yr from cal_dt) */
    @PostMapping
    public ResponseEntity<?> create(@RequestBody CalendarMaster holiday) {
        if (holiday.getCalDt() != null && holiday.getCalYr() == null) {
            holiday.setCalYr(holiday.getCalDt().getYear());
        }

        // Check for duplicate holiday on same date and scope
        if (holiday.getCalDt() != null) {
            List<CalendarMaster> existing = calendarMasterRepository.findByCalDt(holiday.getCalDt());
            for (CalendarMaster ext : existing) {
                if (isDuplicateHoliday(ext, holiday)) {
                    return ResponseEntity.badRequest().body("A holiday with the same date and scope already exists.");
                }
            }
        }

        return ResponseEntity.ok(calendarMasterRepository.save(holiday));
    }

    /** PUT – update holiday */
    @PutMapping("/{id}")
    public ResponseEntity<?> update(
            @PathVariable Long id,
            @RequestBody CalendarMaster details) {

        CalendarMaster holiday = calendarMasterRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Holiday not found: " + id));

        // Check for duplicate holiday on same date and scope, excluding self
        if (details.getCalDt() != null) {
            List<CalendarMaster> existing = calendarMasterRepository.findByCalDt(details.getCalDt());
            for (CalendarMaster ext : existing) {
                if (!ext.getClId().equals(id) && isDuplicateHoliday(ext, details)) {
                    return ResponseEntity.badRequest().body("A holiday with the same date and scope already exists.");
                }
            }
        }

        holiday.setCalDt(details.getCalDt());
        holiday.setHolidayNm(details.getHolidayNm());
        holiday.setCoyId(details.getCoyId());
        holiday.setPltId(details.getPltId());
        holiday.setCalType(details.getCalType());
        holiday.setHolTyp(details.getHolTyp());
        holiday.setAddedBy(details.getAddedBy());

        if (details.getCalDt() != null) {
            holiday.setCalYr(details.getCalDt().getYear());
        }

        return ResponseEntity.ok(calendarMasterRepository.save(holiday));
    }

    private boolean isDuplicateHoliday(CalendarMaster h1, CalendarMaster h2) {
        String holTyp1 = h1.getHolTyp() != null ? h1.getHolTyp() : "";
        String holTyp2 = h2.getHolTyp() != null ? h2.getHolTyp() : "";
        if (!holTyp1.equals(holTyp2)) {
            return false;
        }

        String calType1 = h1.getCalType() != null ? h1.getCalType() : "";
        String calType2 = h2.getCalType() != null ? h2.getCalType() : "";
        if (!calType1.equals(calType2)) {
            return false;
        }

        Integer coyId1 = h1.getCoyId() != null ? h1.getCoyId() : 0;
        Integer coyId2 = h2.getCoyId() != null ? h2.getCoyId() : 0;
        if (!coyId1.equals(coyId2)) {
            return false;
        }

        Integer pltId1 = h1.getPltId() != null ? h1.getPltId() : 0;
        Integer pltId2 = h2.getPltId() != null ? h2.getPltId() : 0;
        if (!pltId1.equals(pltId2)) {
            return false;
        }

        return true;
    }

    /** DELETE */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        calendarMasterRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
