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
        if (holiday.getCalDt() != null) {
            LocalDate today = LocalDate.now();
            int currentYear = today.getYear();
            int holidayYear = holiday.getCalDt().getYear();
            
            if (holidayYear < currentYear) {
                return ResponseEntity.badRequest().body("Cannot save holidays for past years.");
            }
            if (holidayYear > currentYear) {
                return ResponseEntity.badRequest().body("Holidays can only be saved up to December of the current year.");
            }
            
            // Check for duplicate holiday on same date
            List<CalendarMaster> existing = calendarMasterRepository.findByCalDt(holiday.getCalDt());
            for (CalendarMaster ext : existing) {
                if (isDuplicateHoliday(ext, holiday)) {
                    return ResponseEntity.badRequest().body("A holiday with the same date already exists.");
                }
            }
        }

        CalendarMaster savedHoliday = calendarMasterRepository.save(holiday);

        // If isRegular is true, create for next year automatically
        if (Boolean.TRUE.equals(holiday.getIsRegular()) && holiday.getCalDt() != null) {
            int currentYear = LocalDate.now().getYear();
            int nextYear = holiday.getCalDt().getYear() + 1;
            
            if (nextYear <= currentYear + 1) {
                CalendarMaster nextYearHoliday = new CalendarMaster();
                nextYearHoliday.setCalDt(holiday.getCalDt().plusYears(1));

                nextYearHoliday.setHolidayNm(holiday.getHolidayNm());
                nextYearHoliday.setHolTyp(holiday.getHolTyp());
                nextYearHoliday.setAddedBy(holiday.getAddedBy());
                nextYearHoliday.setIsRegular(holiday.getIsRegular());
                
                boolean isDuplicate = false;
                List<CalendarMaster> existingNextYear = calendarMasterRepository.findByCalDt(nextYearHoliday.getCalDt());
                for (CalendarMaster ext : existingNextYear) {
                    if (isDuplicateHoliday(ext, nextYearHoliday)) {
                        isDuplicate = true;
                        break;
                    }
                }
                if (!isDuplicate) {
                    calendarMasterRepository.save(nextYearHoliday);
                }
            }
        }

        return ResponseEntity.ok(savedHoliday);
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
            LocalDate today = LocalDate.now();
            int currentYear = today.getYear();
            int holidayYear = details.getCalDt().getYear();
            
            if (holidayYear < currentYear) {
                return ResponseEntity.badRequest().body("Cannot save holidays for past years.");
            }
            if (holidayYear > currentYear) {
                return ResponseEntity.badRequest().body("Holidays can only be saved up to December of the current year.");
            }

            List<CalendarMaster> existing = calendarMasterRepository.findByCalDt(details.getCalDt());
            for (CalendarMaster ext : existing) {
                if (!ext.getClId().equals(id) && isDuplicateHoliday(ext, details)) {
                    return ResponseEntity.badRequest().body("A holiday with the same date already exists.");
                }
            }
        }

        holiday.setCalDt(details.getCalDt());
        holiday.setHolidayNm(details.getHolidayNm());
        holiday.setHolTyp(details.getHolTyp());
        holiday.setAddedBy(details.getAddedBy());
        holiday.setIsRegular(details.getIsRegular());


        return ResponseEntity.ok(calendarMasterRepository.save(holiday));
    }

    private boolean isDuplicateHoliday(CalendarMaster h1, CalendarMaster h2) {
        String holTyp1 = h1.getHolTyp() != null ? h1.getHolTyp() : "";
        String holTyp2 = h2.getHolTyp() != null ? h2.getHolTyp() : "";
        if (!holTyp1.equals(holTyp2)) {
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
