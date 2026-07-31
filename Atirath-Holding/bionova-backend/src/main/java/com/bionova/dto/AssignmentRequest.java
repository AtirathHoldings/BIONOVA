package com.bionova.dto;

import com.bionova.entity.Assignment;
import lombok.Data;

@Data
public class AssignmentRequest {
    private Assignment task;
    private boolean excludeSat;
    private boolean excludeSun;
    private boolean includeMandatory;
    private boolean coyHolidays;
    private boolean pltHolidays;
    private boolean extHolidays;
    private Integer coyId;
    private Integer pltId;
    private Integer noOfDays;
}
