package com.bionova.dto;

import com.bionova.entity.EmployeeLoginActivity;
import com.bionova.entity.EmployeeSettings;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeSettingsResponseDto {
    private EmployeeSettings preferences;
    private List<EmployeeLoginActivity> loginActivity;
    private Map<String, String> supportAndAbout;
}
