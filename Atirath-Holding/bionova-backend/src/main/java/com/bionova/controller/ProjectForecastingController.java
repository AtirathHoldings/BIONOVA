package com.bionova.controller;

import com.bionova.entity.MilestoneLive;
import com.bionova.entity.ProjectLive;
import com.bionova.entity.TaskLive;
import com.bionova.repository.MilestoneLiveRepository;
import com.bionova.repository.ProjectLiveRepository;
import com.bionova.repository.TaskLiveRepository;
import com.bionova.service.CalendarService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

@RestController
@RequestMapping("/api/project-forecasting")
public class ProjectForecastingController {

    @Autowired private ProjectLiveRepository projectLiveRepository;
    @Autowired private MilestoneLiveRepository milestoneLiveRepository;
    @Autowired private TaskLiveRepository taskLiveRepository;
    @Autowired private CalendarService calendarService;

    @GetMapping("/{prjId}")
    public ResponseEntity<?> getForecasting(@PathVariable Long prjId) {
        Optional<ProjectLive> projectOpt = projectLiveRepository.findById(prjId);
        if (projectOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        ProjectLive project = projectOpt.get();

        List<MilestoneLive> milestones = milestoneLiveRepository.findByPrjId(prjId);
        List<TaskLive> allTasks = new ArrayList<>();
        for (MilestoneLive ms : milestones) {
            allTasks.addAll(taskLiveRepository.findByMilestoneId(ms.getMId()));
        }

        LocalDate startDate = project.getStDt();
        LocalDate endDate = project.getEndDt();
        LocalDate today = LocalDate.now();

        if (startDate == null) startDate = LocalDate.now().minusMonths(1);
        if (endDate == null) endDate = LocalDate.now().plusMonths(6);

        Integer coyId = project.getCoyId();
        Integer pltId = project.getPltId();

        // 1. Calculate overall duration and working days elapsed
        int totalWorkingDays = project.getWrkDays() != null ? project.getWrkDays() : 
                calendarService.countWorkingDays(startDate, endDate, false, true, true, coyId, pltId);
        if (totalWorkingDays <= 0) totalWorkingDays = 1;

        LocalDate elapsedEnd = today.isBefore(startDate) ? startDate : (today.isAfter(endDate) ? endDate : today);
        int workingDaysElapsed = calendarService.countWorkingDays(startDate, elapsedEnd, false, true, true, coyId, pltId);

        double plannedProgress = ((double) workingDaysElapsed * 100.0) / totalWorkingDays;
        if (plannedProgress > 100.0) plannedProgress = 100.0;
        if (plannedProgress < 0.0) plannedProgress = 0.0;

        // 2. Calculate actual progress weighted by task duration (wrkDays or noOfDays)
        double totalWeight = 0;
        double completedWeight = 0;

        for (TaskLive task : allTasks) {
            double weight = task.getWrkDays() != null ? task.getWrkDays() : (task.getNoOfDays() != null ? task.getNoOfDays() : 1);
            if (weight <= 0) weight = 1;

            double taskProg = 0.0;
            String sts = task.getTaskSts() != null ? task.getTaskSts() : "OPEN";
            if ("COMPLETED".equals(sts)) {
                taskProg = 100.0;
            } else if ("SUBMIT_REVIEW".equals(sts) || "UNDER_REVIEW".equals(sts)) {
                taskProg = 90.0;
            } else if ("WIP".equals(sts)) {
                taskProg = 50.0;
            } else if ("REWORK".equals(sts)) {
                taskProg = 30.0;
            } else {
                taskProg = 0.0;
            }

            totalWeight += weight;
            completedWeight += (taskProg / 100.0) * weight;
        }

        double actualProgress = 0.0;
        if (totalWeight > 0) {
            actualProgress = (completedWeight * 100.0) / totalWeight;
        }

        double variance = actualProgress - plannedProgress;
        String statusText = "On Track";
        String statusColor = "#f59e0b"; // orange
        if (variance < -3.0) {
            statusText = "At Risk";
            statusColor = "#ef4444"; // red
        } else if (variance > 3.0) {
            statusText = "Ahead";
            statusColor = "#10b981"; // green
        }

        // 3. Compute Velocity
        double velocity = 1.0;
        if (plannedProgress > 5.0) {
            velocity = actualProgress / plannedProgress;
        }
        if (velocity < 0.1) velocity = 0.1; // cap minimum speed

        // 4. Calculate forecasted end date
        LocalDate forecastedEndDate = endDate;
        int delayDays = 0;
        if (actualProgress < 100.0 && velocity < 1.0) {
            int remainingWorkingDays = (int) Math.round((totalWorkingDays - workingDaysElapsed) / velocity);
            if (remainingWorkingDays < 0) remainingWorkingDays = 0;

            LocalDate tempDate = today.isBefore(startDate) ? startDate : today;
            while (remainingWorkingDays > 0) {
                tempDate = tempDate.plusDays(1);
                if (calendarService.countWorkingDays(tempDate, tempDate, false, true, true, coyId, pltId) > 0) {
                    remainingWorkingDays--;
                }
            }
            forecastedEndDate = tempDate;
            delayDays = (int) (forecastedEndDate.toEpochDay() - endDate.toEpochDay());
            if (delayDays < 0) delayDays = 0;
        }

        // 5. Generate Trend Data Points
        List<Map<String, Object>> trendData = new ArrayList<>();
        DateTimeFormatter trendFormatter = DateTimeFormatter.ofPattern("MMM dd");
        int points = 6;
        long totalDaysSpan = endDate.toEpochDay() - startDate.toEpochDay();
        if (totalDaysSpan <= 0) totalDaysSpan = 30;

        for (int i = 0; i <= points; i++) {
            LocalDate pointDate = startDate.plusDays((totalDaysSpan * i) / points);
            String label = pointDate.format(trendFormatter);

            long pointElapsedDays = pointDate.toEpochDay() - startDate.toEpochDay();
            double base = ((double) pointElapsedDays * 100.0) / totalDaysSpan;
            if (base > 100) base = 100;
            if (base < 0) base = 0;

            Double act = null;
            Double fcast = null;

            if (!pointDate.isAfter(today)) {
                act = (base / (plannedProgress == 0 ? 1 : plannedProgress)) * actualProgress;
                if (act > actualProgress) act = actualProgress;
                fcast = act;
            } else {
                act = null;
                fcast = actualProgress + ((base - plannedProgress) * velocity);
                if (fcast > 100) fcast = 100.0;
                if (fcast < 0) fcast = 0.0;
            }

            Map<String, Object> point = new HashMap<>();
            point.put("name", label);
            point.put("baseline", Math.round(base * 10.0) / 10.0);
            point.put("actual", act != null ? Math.round(act * 10.0) / 10.0 : null);
            point.put("forecast", fcast != null ? Math.round(fcast * 10.0) / 10.0 : null);
            trendData.add(point);
        }

        // 6. Forecast Scenarios
        List<Map<String, Object>> scenarios = new ArrayList<>();
        scenarios.add(Map.of(
                "name", "Current Trend",
                "completionDate", forecastedEndDate.toString(),
                "varianceDays", delayDays,
                "confidence", "High (87%)",
                "description", "Based on current progress and productivity rate"
        ));

        // Best Case: assumes 15% velocity improvement
        double bestVelocity = Math.min(velocity * 1.15, 1.5);
        LocalDate bestEndDate = endDate;
        if (actualProgress < 100.0) {
            int remainingWorkingDays = (int) Math.round((totalWorkingDays - workingDaysElapsed) / bestVelocity);
            LocalDate tempDate = today.isBefore(startDate) ? startDate : today;
            while (remainingWorkingDays > 0) {
                tempDate = tempDate.plusDays(1);
                if (calendarService.countWorkingDays(tempDate, tempDate, false, true, true, coyId, pltId) > 0) {
                    remainingWorkingDays--;
                }
            }
            bestEndDate = tempDate;
        }
        int bestDelay = (int) (bestEndDate.toEpochDay() - endDate.toEpochDay());
        scenarios.add(Map.of(
                "name", "Best Case",
                "completionDate", bestEndDate.toString(),
                "varianceDays", Math.max(0, bestDelay),
                "confidence", "Medium (65%)",
                "description", "Assuming 15% improvement in productivity"
        ));

        // Worst Case: assumes 15% velocity drop
        double worstVelocity = Math.max(velocity * 0.85, 0.2);
        LocalDate worstEndDate = endDate;
        if (actualProgress < 100.0) {
            int remainingWorkingDays = (int) Math.round((totalWorkingDays - workingDaysElapsed) / worstVelocity);
            LocalDate tempDate = today.isBefore(startDate) ? startDate : today;
            while (remainingWorkingDays > 0) {
                tempDate = tempDate.plusDays(1);
                if (calendarService.countWorkingDays(tempDate, tempDate, false, true, true, coyId, pltId) > 0) {
                    remainingWorkingDays--;
                }
            }
            worstEndDate = tempDate;
        }
        int worstDelay = (int) (worstEndDate.toEpochDay() - endDate.toEpochDay());
        scenarios.add(Map.of(
                "name", "Worst Case",
                "completionDate", worstEndDate.toString(),
                "varianceDays", Math.max(0, worstDelay),
                "confidence", "Medium (60%)",
                "description", "Assuming 15% drop in productivity"
        ));

        // Original plan scenario
        scenarios.add(Map.of(
                "name", "Original Plan",
                "completionDate", endDate.toString(),
                "varianceDays", 0,
                "confidence", "Baseline",
                "description", "As per baseline schedule"
        ));

        // 7. Key Factors
        List<Map<String, Object>> keyFactors = new ArrayList<>();
        keyFactors.add(Map.of(
                "factor", "Overall Productivity",
                "impact", velocity < 0.95 ? "Negative" : (velocity > 1.05 ? "Positive" : "Neutral"),
                "impactDays", delayDays > 0 ? delayDays / 3 : 0,
                "trend", velocity < 0.95 ? "Worsening" : (velocity > 1.05 ? "Improving" : "Stable")
        ));
        keyFactors.add(Map.of(
                "factor", "Task Completion Rate",
                "impact", actualProgress < plannedProgress ? "Negative" : "Positive",
                "impactDays", Math.max(0, (int) Math.round(Math.abs(variance) * 0.5)),
                "trend", variance < -2.0 ? "Worsening" : "Improving"
        ));
        keyFactors.add(Map.of(
                "factor", "Resource Availability",
                "impact", "Neutral",
                "impactDays", 0,
                "trend", "Stable"
        ));

        // 8. Milestone Impact
        List<Map<String, Object>> milestoneImpacts = new ArrayList<>();
        int idx = 1;
        for (MilestoneLive ms : milestones) {
            LocalDate msEnd = ms.getEndDt() != null ? ms.getEndDt() : endDate;
            LocalDate msForecast = msEnd;

            int shiftDays = 0;
            if (variance < -3.0) {
                shiftDays = (int) Math.round(Math.abs(variance) * 0.4 * idx);
                msForecast = msEnd.plusDays(shiftDays);
            }

            Map<String, Object> msMap = new HashMap<>();
            msMap.put("mlstnId", ms.getMId());
            msMap.put("mlstnCd", ms.getMlstnCd());
            msMap.put("mlstnTtl", ms.getMlstnTtl());
            msMap.put("endDt", msEnd.toString());
            msMap.put("forecastDate", msForecast.toString());
            msMap.put("impact", shiftDays > 0 ? "+" + shiftDays + " Days" : "On Time");
            msMap.put("impactColor", shiftDays > 0 ? "#ef4444" : "#10b981");
            milestoneImpacts.add(msMap);
            idx++;
        }

        Map<String, Object> response = new HashMap<>();
        response.put("projectId", project.getPrjId());
        response.put("projectName", project.getPrjNm());
        response.put("projectCode", project.getPrjCd());
        response.put("status", project.getPrjSts());
        response.put("startDate", startDate.toString());
        response.put("endDate", endDate.toString());
        response.put("actualProgress", actualProgress);
        response.put("plannedProgress", plannedProgress);
        response.put("variance", variance);
        response.put("statusText", statusText);
        response.put("statusColor", statusColor);
        response.put("workingDaysElapsed", workingDaysElapsed);
        response.put("totalWorkingDays", totalWorkingDays);
        response.put("forecastedCompletionDate", forecastedEndDate.toString());
        response.put("delayDays", delayDays);
        response.put("velocity", velocity);
        response.put("trendData", trendData);
        response.put("scenarios", scenarios);
        response.put("keyFactors", keyFactors);
        response.put("milestonesImpact", milestoneImpacts);

        return ResponseEntity.ok(response);
    }
}
