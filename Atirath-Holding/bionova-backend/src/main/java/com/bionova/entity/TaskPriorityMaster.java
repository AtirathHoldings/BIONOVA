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
        return getByName(value.toString());
    }

    public static final TaskPriorityMaster LOW = new TaskPriorityMaster(1, "LOW");
    public static final TaskPriorityMaster NORMAL = new TaskPriorityMaster(2, "NORMAL");
    public static final TaskPriorityMaster MEDIUM = new TaskPriorityMaster(3, "MEDIUM");
    public static final TaskPriorityMaster HIGH = new TaskPriorityMaster(4, "HIGH");
    public static final TaskPriorityMaster CRITICAL = new TaskPriorityMaster(5, "CRITICAL");

    public static Integer getPriorityIdByName(String name) {
        if (name == null) return null;
        switch (name.toUpperCase().replace(" ", "_")) {
            case "LOW": return 1;
            case "NORMAL": return 2;
            case "MEDIUM": return 3;
            case "HIGH": return 4;
            case "CRITICAL": return 5;
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
            default: return null;
        }
    }

    /**
     * Dynamically calculates task priority based on start date, end date, total duration,
     * status and actual completion date.
     */
    public static TaskPriorityMaster calculatePriority(LocalDate stDt, LocalDate endDt, Integer noOfDays, TaskStatusMaster status, LocalDate actCmpDt) {
        if (stDt == null) {
            return TaskPriorityMaster.LOW;
        }

        // Determine the total days
        int totalDays = 1;
        if (noOfDays != null && noOfDays > 0) {
            totalDays = noOfDays;
        } else if (endDt != null) {
            totalDays = (int) java.time.temporal.ChronoUnit.DAYS.between(stDt, endDt) + 1;
        }
        if (totalDays <= 0) {
            totalDays = 1;
        }

        // Determine the reference end date for calculation
        LocalDate refDate = LocalDate.now();
        if (status != null && "COMPLETED".equalsIgnoreCase(status.getStatusNm())) {
            if (actCmpDt != null) {
                refDate = actCmpDt;
            } else if (endDt != null) {
                refDate = endDt; // fallback
            }
        }

        long elapsedDays = java.time.temporal.ChronoUnit.DAYS.between(stDt, refDate) + 1;
        if (elapsedDays <= 0) {
            return TaskPriorityMaster.LOW;
        }

        if (totalDays <= 1) {
            return elapsedDays >= 1 ? TaskPriorityMaster.CRITICAL : TaskPriorityMaster.LOW;
        }

        double ratio = (double) (elapsedDays - 1) / (totalDays - 1);
        if (ratio <= 0.1) {
            return TaskPriorityMaster.LOW;
        } else if (ratio <= 0.35) {
            return TaskPriorityMaster.NORMAL;
        } else if (ratio <= 0.65) {
            return TaskPriorityMaster.MEDIUM;
        } else if (ratio <= 0.9) {
            return TaskPriorityMaster.HIGH;
        } else {
            return TaskPriorityMaster.CRITICAL;
        }
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
