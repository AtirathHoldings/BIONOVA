package com.bionova.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ForgotPasswordRequest {
    private String email;
    private String source;      // e.g. "app", "mobile", "web"
    private String client;      // alias for source
    private String platform;    // e.g. "android", "ios", "web"
    private String redirectUrl; // custom base URL/scheme provided by client
}
