package com.bionova.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateEmployeePermissionsRequest {
    private Long empId;
    private List<ScreenPermissionDto> permissions;
    private String createdBy;
    private String customRoleName;
}
