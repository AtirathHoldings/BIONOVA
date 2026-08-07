package com.bionova;

import com.bionova.service.PasswordResetService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class PasswordResetServiceTest {

    private PasswordResetService passwordResetService;

    @BeforeEach
    public void setUp() {
        passwordResetService = new PasswordResetService(null, null, null, null);
    }

    @Test
    public void testIsAppRequestWithSourceApp() {
        assertTrue(passwordResetService.isAppRequest("app", null, null, null, null));
        assertTrue(passwordResetService.isAppRequest("mobile", null, null, null, null));
    }

    @Test
    public void testIsAppRequestWithUserAgent() {
        assertTrue(passwordResetService.isAppRequest(null, null, null, "Dart/3.0 (dart:io)", null));
        assertTrue(passwordResetService.isAppRequest(null, null, null, "cbg_app/1.0", null));
        assertTrue(passwordResetService.isAppRequest(null, null, null, "okhttp/4.9.0", null));
    }

    @Test
    public void testIsAppRequestWithHeader() {
        assertTrue(passwordResetService.isAppRequest(null, null, null, null, "app"));
    }

    @Test
    public void testIsAppRequestForWeb() {
        assertFalse(passwordResetService.isAppRequest("web", null, "web", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)", null));
        assertFalse(passwordResetService.isAppRequest(null, null, null, null, null));
    }
}
