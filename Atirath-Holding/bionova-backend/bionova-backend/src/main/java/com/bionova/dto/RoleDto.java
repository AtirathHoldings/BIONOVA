package com.bionova.dto;

import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
public class RoleDto {
    private Integer roleId;
    private String roleNm;
    private Long permissionsCount;
    private String createdBy;

    public RoleDto(Integer roleId, String roleNm, Long permissionsCount, String createdBy) {
        this.roleId = roleId;
        this.roleNm = roleNm;
        this.permissionsCount = permissionsCount;
        this.createdBy = createdBy;
    }

    public RoleDto(Integer roleId, String roleNm, Double permissionsCount, String createdBy) {
        this.roleId = roleId;
        this.roleNm = roleNm;
        this.permissionsCount = permissionsCount != null ? permissionsCount.longValue() : 0L;
        this.createdBy = createdBy;
    }

    public RoleDto(Integer roleId, String roleNm, Integer permissionsCount, String createdBy) {
        this.roleId = roleId;
        this.roleNm = roleNm;
        this.permissionsCount = permissionsCount != null ? permissionsCount.longValue() : 0L;
        this.createdBy = createdBy;
    }
}
