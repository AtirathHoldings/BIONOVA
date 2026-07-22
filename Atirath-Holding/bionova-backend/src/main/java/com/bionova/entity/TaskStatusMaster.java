package com.bionova.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "task_status_master")
@Getter
@Setter
public class TaskStatusMaster {

    @Id
    @Column(name = "status_id")
    private Integer statusId;

    @Column(name = "status_nm", nullable = false, length = 20)
    private String statusNm;

    @Column(name = "sub_status_nm", length = 255)
    private String subStatusNm;

    public TaskStatusMaster() {}

    public TaskStatusMaster(Integer statusId, String statusNm) {
        this.statusId = statusId;
        this.statusNm = statusNm;
    }

    public TaskStatusMaster(Integer statusId, String statusNm, String subStatusNm) {
        this.statusId = statusId;
        this.statusNm = statusNm;
        this.subStatusNm = subStatusNm;
    }

    public static final TaskStatusMaster DRAFT = new TaskStatusMaster(1, "Draft", null);
    public static final TaskStatusMaster OPEN = new TaskStatusMaster(2, "Open", "Overdue");
    public static final TaskStatusMaster WIP = new TaskStatusMaster(3, "WIP", "Under Review, Reassign, Rework, Overdue");
    public static final TaskStatusMaster CLOSED = new TaskStatusMaster(4, "Closed", "Lead, On Time, Lag");
    public static final TaskStatusMaster HOLD = new TaskStatusMaster(5, "Hold", null);

    public static Integer getStatusIdByName(String name) {
        if (name == null) return null;
        switch (name.toUpperCase().trim().replace(" ", "_")) {
            case "DRAFT": return 1;
            case "OPEN": return 2;
            case "WIP": case "IN_PROGRESS": return 3;
            case "CLOSED": return 4;
            case "HOLD": return 5;
            // Map sub-status names to parent status IDs to support legacy frontend/controllers status updates
            case "UNDER_REVIEW":
            case "REASSIGN":
            case "REWORK":
            case "OVER_DUE":
            case "OVERDUE":
                return 3; // WIP parent status
            case "LEAD":
            case "ON_TIME":
            case "LAG":
                return 4; // CLOSED parent status
            default: return null;
        }
    }

    public static TaskStatusMaster getByName(String name) {
        Integer id = getStatusIdByName(name);
        if (id == null) return null;
        return getById(id);
    }

    public static TaskStatusMaster getById(int id) {
        switch (id) {
            case 1: return DRAFT;
            case 2: return OPEN;
            case 3: return WIP;
            case 4: return CLOSED;
            case 5: return HOLD;
            default: return null;
        }
    }

    public static TaskStatusMaster getByStatusAndSubStatus(String status, String subStatus) {
        if (status == null) return null;
        String normalizedStatus = status.trim();
        if ("IN_PROGRESS".equalsIgnoreCase(normalizedStatus)) {
            normalizedStatus = "WIP";
        }
        return getByName(normalizedStatus);
    }

    @JsonValue
    public String getStatusNm() {
        return statusNm;
    }

    @Override
    public String toString() {
        return statusNm;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof TaskStatusMaster)) return false;
        TaskStatusMaster that = (TaskStatusMaster) o;
        return statusId != null && statusId.equals(that.getStatusId());
    }

    @Override
    public int hashCode() {
        return statusId != null ? statusId.hashCode() : 0;
    }

    @JsonCreator
    public static TaskStatusMaster fromValue(Object value) {
        if (value == null) return null;
        if (value instanceof Number) {
            int id = ((Number) value).intValue();
            return getById(id);
        }
        if (value instanceof String) {
            String str = (String) value;
            if (str.trim().isEmpty()) return null;
            try {
                int id = Integer.parseInt(str.trim());
                return getById(id);
            } catch (NumberFormatException e) {
                return getByName(str);
            }
        }
        return null;
    }
}
