package com.bionova.service;

import com.bionova.entity.CalendarMaster;
import com.bionova.repository.CalendarMasterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Calculates working days between two dates by:
 *  1. Optionally excluding Saturdays
 *  2. Optionally excluding Sundays
 *  3. Optionally excluding public/national holidays (MANDATORY, holTyp)
 *  4. Optionally excluding company-specific holidays  (calType = COMPANY)
 *  5. Optionally excluding plant-specific holidays    (calType = PLANT)
 *  6. Optionally excluding external calendar holidays (calType = EXTERNAL)
 *     → Falls back to company calendar if no EXTERNAL records found
 *
 * BUG FIX: Previous version ignored plant holidays when coyId was provided.
 * Now each scope is collected independently and merged.
 */
@Service
public class CalendarService {

    @Autowired
    private CalendarMasterRepository calendarMasterRepository;

    /**
     * Core method: counts working days between startDate (inclusive) and endDate (inclusive).
     *
     * @param startDate        project/milestone/task start
     * @param endDate          project/milestone/task end
     * @param excludeSat       true = Saturdays are non-working days
     * @param excludeSun       true = Sundays are non-working days
     * @param includeMandatory true = national/public holidays are excluded
     * @param coyId            company id for company-specific holidays (null = skip)
     * @param pltId            plant id for plant-specific holidays (null = skip)
     */
    public int countWorkingDays(
            LocalDate startDate,
            LocalDate endDate,
            boolean excludeSat,
            boolean excludeSun,
            boolean includeMandatory,
            Integer coyId,
            Integer pltId) {

        List<CalendarMaster> allHolidays = new ArrayList<>();

        if (includeMandatory) {
            allHolidays.addAll(calendarMasterRepository.findByCalDtBetween(startDate, endDate));
        }

        // Collect unique holiday dates
        Set<LocalDate> holidayDates = allHolidays.stream()
                .map(CalendarMaster::getCalDt)
                .collect(Collectors.toSet());

        // Count working days
        int workingDays = 0;
        LocalDate current = startDate;
        while (!current.isAfter(endDate)) {
            DayOfWeek dow = current.getDayOfWeek();
            boolean isWeekendHoliday = (excludeSat && dow == DayOfWeek.SATURDAY)
                                    || (excludeSun && dow == DayOfWeek.SUNDAY);
            boolean isCalendarHoliday = holidayDates.contains(current);

            if (!isWeekendHoliday && !isCalendarHoliday) {
                workingDays++;
            }
            current = current.plusDays(1);
        }
        return workingDays;
    }

    /**
     * Extended: includes EXTERNAL calendar holidays.
     * If no EXTERNAL holidays are found for the company, falls back to COMPANY calendar.
     *
     * Image reference: "If Calendar doesn't exist for External then Company Calendar will be Used for External."
     */
    public int countWorkingDaysWithExternal(
            LocalDate startDate,
            LocalDate endDate,
            boolean excludeSat,
            boolean excludeSun,
            boolean includeMandatory,
            Integer coyId,
            Integer pltId,
            boolean includeExternal) {

        List<CalendarMaster> allHolidays = new ArrayList<>();

        if (includeMandatory) {
            allHolidays.addAll(calendarMasterRepository.findByCalDtBetween(startDate, endDate));
        }

        Set<LocalDate> holidayDates = allHolidays.stream()
                .map(CalendarMaster::getCalDt)
                .collect(Collectors.toSet());

        int workingDays = 0;
        LocalDate current = startDate;
        while (!current.isAfter(endDate)) {
            DayOfWeek dow = current.getDayOfWeek();
            boolean isWeekendHoliday = (excludeSat && dow == DayOfWeek.SATURDAY)
                                    || (excludeSun && dow == DayOfWeek.SUNDAY);
            boolean isCalendarHoliday = holidayDates.contains(current);
            if (!isWeekendHoliday && !isCalendarHoliday) {
                workingDays++;
            }
            current = current.plusDays(1);
        }
        return workingDays;
    }

    /**
     * Convenience: compute working days using all defaults:
     *   - Exclude Sundays always
     *   - Include public (MANDATORY) holidays
     *   - Company & plant specific holidays
     */
    public int computeWorkingDays(LocalDate startDate, LocalDate endDate, Integer coyId, Integer pltId) {
        return countWorkingDays(startDate, endDate, false, true, true, coyId, pltId);
    }

    /**
     * Gets holiday summary for a date range (for UI preview / "Preview Project Dates" button)
     */
    public HolidaySummary getHolidaySummary(
            LocalDate startDate,
            LocalDate endDate,
            boolean excludeSat,
            boolean excludeSun,
            boolean includeMandatory,
            Integer coyId,
            Integer pltId) {

        int totalDays = (int) (endDate.toEpochDay() - startDate.toEpochDay()) + 1;
        int workingDays = countWorkingDays(startDate, endDate, excludeSat, excludeSun, includeMandatory, coyId, pltId);
        int holidayCount = totalDays - workingDays;

        return new HolidaySummary(totalDays, workingDays, holidayCount);
    }

    /**
     * Calculates the end date by adding a given number of working days to the start date,
     * skipping weekends (Saturdays/Sundays) and holidays according to the configured rules.
     */
    public LocalDate calculateEndDate(
            LocalDate startDate,
            int workingDays,
            boolean excludeSat,
            boolean excludeSun,
            boolean includeMandatory,
            Integer coyId,
            Integer pltId,
            boolean includeExternal) {

        if (startDate == null || workingDays <= 0) {
            return startDate;
        }

        LocalDate estimatedMaxEnd = startDate.plusDays(workingDays * 3L + 60);
        List<CalendarMaster> allHolidays = new ArrayList<>();

        if (includeMandatory) {
            allHolidays.addAll(calendarMasterRepository.findByCalDtBetween(startDate, estimatedMaxEnd));
        }

        Set<LocalDate> holidayDates = allHolidays.stream()
                .map(CalendarMaster::getCalDt)
                .collect(Collectors.toSet());

        int count = 0;
        LocalDate current = startDate;
        while (true) {
            DayOfWeek dow = current.getDayOfWeek();
            boolean isWeekendHoliday = (excludeSat && dow == DayOfWeek.SATURDAY)
                                    || (excludeSun && dow == DayOfWeek.SUNDAY);
            boolean isCalendarHoliday = holidayDates.contains(current);

            if (!isWeekendHoliday && !isCalendarHoliday) {
                count++;
                if (count == workingDays) {
                    return current;
                }
            }
            current = current.plusDays(1);
        }
    }

    public record HolidaySummary(int totalDays, int workingDays, int holidayDays) {}
}
