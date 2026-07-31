package com.bionova.dto;

import lombok.Data;
import java.util.List;

@Data
public class SaveRoleRequest {
    private String roleNm;
    private List<ScreenPermissionDto> permissions;
    private String createdBy;
}
