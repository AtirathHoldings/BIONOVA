package com.bionova.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Entity
@Table(name = "task_priority_master")
@Getter
@Setter
public class TaskPriorityMaster {

    @Id
    @Column(name = "priority_id")
    private Integer priorityId;

    @Column(name = "priority_nm", nullable = false, unique = true, length = 20)
    private String priorityNm;

    public TaskPriorityMaster() {}

    public TaskPriorityMaster(Integer priorityId, String priorityNm) {
        this.priorityId = priorityId;
        this.priorityNm = priorityNm;
    }

    @JsonValue
    public String getPriorityNm() {
        return priorityNm;
    }

    @JsonCreator
    public static TaskPriorityMaster fromValue(Object value) {
        if (value == null) return null;
        if (value instanceof Number) {
            return getById(((Number) value).intValue());
        }
        if (value instanceof java.util.Map) {
            java.util.Map<?, ?> map = (java.util.Map<?, ?>) value;
            Object id = map.get("priorityId");
            if (id instanceof Number) {
                return getById(((Number) id).intValue());
            } else if (id != null) {
                try {
                    return getById(Integer.parseInt(id.toString()));
                } catch (NumberFormatException ignored) {}
            }
            Object nm = map.get("priorityNm");
            if (nm != null) {
                return getByName(nm.toString());
            }
        }
        String str = value.toString().trim();
        try {
            int numId = Integer.parseInt(str);
            return getById(numId);
        } catch (NumberFormatException ignored) {}
        return getByName(str);
    }

    public static final TaskPriorityMaster LOW = new TaskPriorityMaster(1, "LOW");
    public static final TaskPriorityMaster NORMAL = new TaskPriorityMaster(2, "NORMAL");
    public static final TaskPriorityMaster MEDIUM = new TaskPriorityMaster(3, "MEDIUM");
    public static final TaskPriorityMaster HIGH = new TaskPriorityMaster(4, "HIGH");
    public static final TaskPriorityMaster CRITICAL = new TaskPriorityMaster(5, "CRITICAL");
    public static final TaskPriorityMaster ATMOST_CRITICAL = new TaskPriorityMaster(6, "ATMOST CRITICAL");

    public static Integer getPriorityIdByName(String name) {
        if (name == null) return null;
        switch (name.toUpperCase().replace(" ", "_")) {
            case "LOW": return 1;
            case "NORMAL": return 2;
            case "MEDIUM": return 3;
            case "HIGH": return 4;
            case "CRITICAL": return 5;
            case "ATMOST_CRITICAL":
            case "AT_MOST_CRITICAL": return 6;
            default: return null;
        }
    }

    public static TaskPriorityMaster getByName(String name) {
        if (name == null) return null;
        switch (name.toUpperCase().replace(" ", "_")) {
            case "LOW": return LOW;
            case "NORMAL": return NORMAL;
            case "MEDIUM": return MEDIUM;
            case "HIGH": return HIGH;
            case "CRITICAL": return CRITICAL;
            case "ATMOST_CRITICAL":
            case "AT_MOST_CRITICAL": return ATMOST_CRITICAL;
            default: return null;
        }
    }

    public static TaskPriorityMaster getById(Integer id) {
        if (id == null) return null;
        switch (id) {
            case 1: return LOW;
            case 2: return NORMAL;
            case 3: return MEDIUM;
            case 4: return HIGH;
            case 5: return CRITICAL;
            case 6: return ATMOST_CRITICAL;
            default: return null;
        }
    }

    /**
     * Dynamically calculates task priority based on start date, end date, total duration,
     * status, actual completion date, and initial base priority.
     */
    public static TaskPriorityMaster calculatePriority(LocalDate stDt, LocalDate endDt, Integer noOfDays, TaskStatusMaster status, LocalDate actCmpDt, TaskPriorityMaster initialPriority) {
        TaskPriorityMaster baseP = (initialPriority != null) ? initialPriority : TaskPriorityMaster.LOW;
        if (stDt == null) {
            return baseP;
        }

        // Determine total days
        int totalDays = 1;
        if (noOfDays != null && noOfDays > 0) {
            totalDays = noOfDays;
        } else if (endDt != null) {
            totalDays = (int) java.time.temporal.ChronoUnit.DAYS.between(stDt, endDt) + 1;
        }
        if (totalDays <= 0) {
            totalDays = 1;
        }

        // Determine reference date for calculation
        LocalDate refDate = LocalDate.now();
        if (actCmpDt != null) {
            refDate = actCmpDt;
        } else if (status != null && "CLOSED".equalsIgnoreCase(status.getStatusNm()) && endDt != null) {
            refDate = endDt;
        }

        long elapsedDays = java.time.temporal.ChronoUnit.DAYS.between(stDt, refDate) + 1;
        if (elapsedDays <= 0) {
            return baseP;
        }

        int baseId = baseP.getPriorityId() != null ? baseP.getPriorityId() : 1;
        if (baseId > 4) {
            baseId = 4; // Capped base level at HIGH for duration calculations
        }

        // Number of priority levels from baseId up to HIGH (4)
        int numLevels = 4 - baseId + 1;
        if (numLevels <= 0) numLevels = 1;

        double step = (double) totalDays / numLevels;

        if (elapsedDays <= totalDays) {
            int levelIndex = (int) Math.floor((elapsedDays - 1) / step);
            if (levelIndex >= numLevels) {
                levelIndex = numLevels - 1;
            }
            int targetId = baseId + levelIndex;
            if (targetId > 4) targetId = 4; // Cap at HIGH during normal duration
            TaskPriorityMaster result = getById(targetId);
            return result != null ? result : baseP;
        } else {
            long overdueDays = elapsedDays - totalDays;
            if (overdueDays <= step) {
                return TaskPriorityMaster.CRITICAL;
            } else {
                return TaskPriorityMaster.ATMOST_CRITICAL;
            }
        }
    }

    public static TaskPriorityMaster calculatePriority(LocalDate stDt, LocalDate endDt, Integer noOfDays, TaskStatusMaster status, LocalDate actCmpDt) {
        return calculatePriority(stDt, endDt, noOfDays, status, actCmpDt, null);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof TaskPriorityMaster)) return false;
        TaskPriorityMaster that = (TaskPriorityMaster) o;
        return priorityId != null && priorityId.equals(that.getPriorityId());
    }

    @Override
    public int hashCode() {
        return priorityId != null ? priorityId.hashCode() : 0;
    }
}
