package com.bionova.controller;

import com.bionova.entity.CalendarMaster;
import com.bionova.repository.CalendarMasterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/calendar")
public class CalendarMasterController {

    @Autowired
    private CalendarMasterRepository calendarMasterRepository;

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

    /** POST – add a holiday (auto-fills cal_yr from cal_dt) */
    @PostMapping
    public ResponseEntity<CalendarMaster> create(@RequestBody CalendarMaster holiday) {
        // Auto-extract year from date if not provided
        if (holiday.getCalDt() != null && holiday.getCalYr() == null) {
            holiday.setCalYr(holiday.getCalDt().getYear());
        }
        if (holiday.getSts() == null) {
            holiday.setSts(true);
        }
        CalendarMaster saved = calendarMasterRepository.save(holiday);
        return ResponseEntity.ok(saved);
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
        holiday.setHolTyp(details.getHolTyp());
        holiday.setAddlRem(details.getAddlRem());
        holiday.setSts(details.getSts());

        if (details.getCalDt() != null) {
            holiday.setCalYr(details.getCalDt().getYear());
        }

        return ResponseEntity.ok(calendarMasterRepository.save(holiday));
    }

    /** PATCH – toggle active/inactive */
    @PatchMapping("/{id}/toggle-status")
    public ResponseEntity<CalendarMaster> toggleStatus(@PathVariable Long id) {
        CalendarMaster holiday = calendarMasterRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Holiday not found: " + id));
        holiday.setSts(!Boolean.TRUE.equals(holiday.getSts()));
        return ResponseEntity.ok(calendarMasterRepository.save(holiday));
    }

    /** DELETE */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        calendarMasterRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}
