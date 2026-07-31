package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ScreenPermissionDto {
    private Integer screenId;
    private String screenNm;
    private String groupNm;
    private String screenCode;
    private Boolean viewFlg;
    private Boolean editFlg;
    private Boolean addFlg;
    private Boolean deleteFlg;
    private String accessType; // e.g., "From Template", "Extra Added", "Revoked", "Mixed"
}
