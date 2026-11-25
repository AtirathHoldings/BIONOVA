package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class LoginResponse {

    private boolean success;
    private String message;
    private String role;
    private String token;
    private Long empId;
    private String landingRoute;
    private String defaultScreen;
    private Boolean hasRbac;

    public LoginResponse(boolean success, String message, String role, String token, Long empId) {
        this.success = success;
        this.message = message;
        this.role = role;
        this.token = token;
        this.empId = empId;
    }
}
