package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PacEmployeeDto {
    private Long empId;
    private String empCd;
    private String name;
    private String avatar;
    private List<String> permissions;
}
