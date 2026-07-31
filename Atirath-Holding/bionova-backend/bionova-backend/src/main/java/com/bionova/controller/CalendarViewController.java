package com.bionova.controller;

import com.bionova.dto.CalendarEventDto;
import com.bionova.entity.CalendarMaster;
import com.bionova.entity.Employee;
import com.bionova.entity.MilestoneLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.CalendarMasterRepository;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.repository.AssignmentRepository;
import com.bionova.entity.Assignment;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/calendar/user-feed")
public class CalendarViewController {

    @Autowired
    private TaskLiveRepository taskLiveRepository;

    @Autowired
    private MilestoneLiveRepository milestoneLiveRepository;

    @Autowired
    private CalendarMasterRepository calendarMasterRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private AssignmentRepository employeeIndividualTaskRepository;

    /**
     * Fetch calendar feed (Holidays, Tasks, and Milestones) for the logged-in employee.
     * Supports weekly, monthly, and day-wise filtering.
     * 
     * @param viewType "month", "week", or "day" (defaults to "month")
     * @param date Reference date in YYYY-MM-DD format (defaults to today)
     */
    @GetMapping
    public ResponseEntity<List<CalendarEventDto>> getUserCalendar(
            @RequestParam(value = "viewType", defaultValue = "month") String viewType,
            @RequestParam(value = "date", required = false) String date) {

        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        Employee employee = employeeRepository.findByEmail(email).orElse(null);

        LocalDate refDate = (date != null) ? LocalDate.parse(date) : LocalDate.now();
        LocalDate startDate;
        LocalDate endDate;

        // Calculate date range based on viewType
        if ("day".equalsIgnoreCase(viewType)) {
            startDate = refDate;
            endDate = refDate;
        } else if ("week".equalsIgnoreCase(viewType)) {
            // Start of week (Sunday) to end of week (Saturday)
            int dayOfWeek = refDate.getDayOfWeek().getValue();
            int daysFromSunday = (dayOfWeek == 7) ? 0 : dayOfWeek;
            startDate = refDate.minusDays(daysFromSunday);
            endDate = startDate.plusDays(6);
        } else {
            // Month view (default) - include previous month's prefix days and next month's suffix days in the grid
            LocalDate firstOfMonth = refDate.withDayOfMonth(1);
            int firstDayOfWeekVal = firstOfMonth.getDayOfWeek().getValue();
            int daysFromSunday = (firstDayOfWeekVal == 7) ? 0 : firstDayOfWeekVal;
            startDate = firstOfMonth.minusDays(daysFromSunday);

            LocalDate lastOfMonth = refDate.withDayOfMonth(refDate.lengthOfMonth());
            int lastDayOfWeekVal = lastOfMonth.getDayOfWeek().getValue();
            int daysToSaturday = (lastDayOfWeekVal == 7) ? 6 : (6 - lastDayOfWeekVal);
            endDate = lastOfMonth.plusDays(daysToSaturday);
        }

        List<CalendarEventDto> events = new ArrayList<>();

        // 1. Fetch & Map Holidays
        List<CalendarMaster> holidays = calendarMasterRepository.findAll().stream()
                .filter(h -> h.getCalDt() != null && !h.getCalDt().isBefore(startDate) && !h.getCalDt().isAfter(endDate))
                .collect(Collectors.toList());

        for (CalendarMaster hol : holidays) {
            events.add(new CalendarEventDto(
                    "HOLIDAY-" + hol.getClId(),
                    hol.getHolidayNm(),
                    "HOLIDAY",
                    hol.getCalDt(),
                    null,
                    hol.getHolTyp(),
                    null,
                    "Holiday: " + hol.getHolidayNm()
            ));
        }

        if (employee != null) {
            // 2. Fetch & Map Tasks assigned to this employee in the date range
            List<TaskLive> allEmployeeTasks = taskLiveRepository.findByEmpId(employee.getEmpId());
            
            List<TaskLive> rangeTasks = allEmployeeTasks.stream()
                    .filter(t -> t.getEndDt() != null && !t.getEndDt().isBefore(startDate) && !t.getEndDt().isAfter(endDate))
                    .collect(Collectors.toList());

            for (TaskLive task : rangeTasks) {
                events.add(new CalendarEventDto(
                        "TASK-" + task.getTaskId(),
                        task.getTaskNm(),
                        "TASK",
                        task.getEndDt(),
                        null,
                        task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "OPEN",
                        task.getTaskCd(),
                        task.getTaskDesc()
                ));
            }

            // 2b. Fetch & Map Individual Tasks assigned to this employee in the date range
            List<Assignment> allIndividualTasks = employeeIndividualTaskRepository.findByEmpId(employee.getEmpId());
            
            List<Assignment> rangeIndTasks = allIndividualTasks.stream()
                    .filter(t -> t.getEndDt() != null && !t.getEndDt().isBefore(startDate) && !t.getEndDt().isAfter(endDate))
                    .collect(Collectors.toList());

            for (Assignment task : rangeIndTasks) {
                events.add(new CalendarEventDto(
                        "IND-TASK-" + task.getEmpTaskId(),
                        task.getTaskNm(),
                        "TASK",
                        task.getEndDt(),
                        null,
                        task.getTaskSts() != null ? task.getTaskSts().getStatusNm() : "DRAFT",
                        task.getTaskCd(),
                        task.getTaskDesc()
                ));
            }

            // 3. Fetch & Map Milestones associated with employee's assigned tasks
            Set<Long> milestoneIdsForEmployee = allEmployeeTasks.stream()
                    .map(TaskLive::getMId)
                    .filter(Objects::nonNull)
                    .collect(Collectors.toSet());

            if (!milestoneIdsForEmployee.isEmpty()) {
                List<MilestoneLive> milestones = milestoneLiveRepository.findAllById(milestoneIdsForEmployee).stream()
                        .filter(m -> m.getEndDt() != null && !m.getEndDt().isBefore(startDate) && !m.getEndDt().isAfter(endDate))
                        .collect(Collectors.toList());

                for (MilestoneLive ms : milestones) {
                    events.add(new CalendarEventDto(
                            "MILESTONE-" + ms.getMId(),
                            ms.getMlstnTtl(),
                            "MILESTONE",
                            ms.getEndDt(),
                            null,
                            ms.getMlstnSts(),
                            ms.getMlstnCd(),
                            ms.getMlstnDesc()
                    ));
                }
            }
        }

        // Sort events chronologically
        events.sort(Comparator.comparing(CalendarEventDto::getDate));

        return ResponseEntity.ok(events);
    }
}
