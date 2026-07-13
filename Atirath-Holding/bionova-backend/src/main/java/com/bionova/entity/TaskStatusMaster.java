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

    @Column(name = "status_nm", unique = true, nullable = false, length = 20)
    private String statusNm;

    public TaskStatusMaster() {}

    public TaskStatusMaster(Integer statusId, String statusNm) {
        this.statusId = statusId;
        this.statusNm = statusNm;
    }

    public static final TaskStatusMaster DRAFT = new TaskStatusMaster(1, "DRAFT");
    public static final TaskStatusMaster OPEN = new TaskStatusMaster(2, "OPEN");
    public static final TaskStatusMaster WIP = new TaskStatusMaster(3, "WIP");
    public static final TaskStatusMaster UNDER_REVIEW = new TaskStatusMaster(4, "UNDER_REVIEW");
    public static final TaskStatusMaster COMPLETED = new TaskStatusMaster(5, "COMPLETED");
    public static final TaskStatusMaster REASSIGN = new TaskStatusMaster(6, "REASSIGN");
    public static final TaskStatusMaster REWORK = new TaskStatusMaster(7, "REWORK");
    public static final TaskStatusMaster OVER_DUE = new TaskStatusMaster(8, "OVER_DUE");

    public static Integer getStatusIdByName(String name) {
        if (name == null) return null;
        switch (name.toUpperCase().replace(" ", "_")) {
            case "DRAFT": return 1;
            case "OPEN": return 2;
            case "WIP": return 3;
            case "UNDER_REVIEW": return 4;
            case "COMPLETED": return 5;
            case "REASSIGN": return 6;
            case "REWORK": return 7;
            case "OVER_DUE": case "OVERDUE": return 8;
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
            case 4: return UNDER_REVIEW;
            case 5: return COMPLETED;
            case 6: return REASSIGN;
            case 7: return REWORK;
            case 8: return OVER_DUE;
            default: return null;
        }
    }

    @JsonValue
    public String getStatusNm() {
        return statusNm;
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
