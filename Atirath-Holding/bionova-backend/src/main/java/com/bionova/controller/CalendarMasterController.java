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
    public ResponseEntity<CalendarMaster> create(@RequestBody CalendarMaster holiday) {
        if (holiday.getCalDt() != null && holiday.getCalYr() == null) {
            holiday.setCalYr(holiday.getCalDt().getYear());
        }
        return ResponseEntity.ok(calendarMasterRepository.save(holiday));
    }

    /** PUT – update holiday */
    @PutMapping("/{id}")
    public ResponseEntity<CalendarMaster> update(
            @PathVariable Long id,
            @RequestBody CalendarMaster details) {

        CalendarMaster holiday = calendarMasterRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Holiday not found: " + id));

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

    /** DELETE */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        calendarMasterRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
