package com.bionova.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeePermissionsDto {
    private Long employeeId;
    private String name;
    private String email;
    private String code;
    private String role;
    private List<ScreenPermissionDto> permissions;
}
