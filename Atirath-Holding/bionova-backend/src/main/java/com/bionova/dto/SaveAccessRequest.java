package com.bionova.dto;

import lombok.Data;
import java.util.List;

@Data
public class SaveAccessRequest {
    private List<Long> empIds;
    private Integer roleId;
    private String customRoleName;
    private List<ScreenPermissionDto> permissions;
}
