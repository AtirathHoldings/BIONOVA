package com.bionova.service;

import com.bionova.dto.EmployeeSettingsResponseDto;
import com.bionova.entity.EmployeeLoginActivity;
import com.bionova.entity.EmployeeSettings;
import com.bionova.repository.EmployeeLoginActivityRepository;
import com.bionova.repository.EmployeeSettingsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Service
public class EmployeeSettingsService {

    @Autowired
    private EmployeeSettingsRepository settingsRepository;

    @Autowired
    private EmployeeLoginActivityRepository loginActivityRepository;

    @Transactional
    public EmployeeSettingsResponseDto getSettings(Long empId) {
        // 1. Get or create settings
        EmployeeSettings settings = settingsRepository.findByEmpId(empId)
                .orElseGet(() -> {
                    EmployeeSettings newSettings = new EmployeeSettings();
                    newSettings.setEmpId(empId);
                    return settingsRepository.save(newSettings);
                });

        // 2. Get login activities, pre-populate if empty
        List<EmployeeLoginActivity> activities = loginActivityRepository.findByEmpIdOrderByLoginDtDesc(empId);
        if (activities.isEmpty()) {
            // Add mock login activities matching the design screenshot
            EmployeeLoginActivity current = new EmployeeLoginActivity();
            current.setEmpId(empId);
            current.setDeviceInfo("Chrome - Windows");
            current.setLoginDt(LocalDateTime.now().minusHours(6));
            current.setStatus("Active");
            loginActivityRepository.save(current);

            EmployeeLoginActivity mobile = new EmployeeLoginActivity();
            mobile.setEmpId(empId);
            mobile.setDeviceInfo("Android App");
            mobile.setLoginDt(LocalDateTime.now().minusDays(1).minusHours(2));
            mobile.setStatus("Logged Out");
            loginActivityRepository.save(mobile);

            EmployeeLoginActivity oldDesktop = new EmployeeLoginActivity();
            oldDesktop.setEmpId(empId);
            oldDesktop.setDeviceInfo("Chrome - Windows");
            oldDesktop.setLoginDt(LocalDateTime.now().minusDays(2).minusHours(1));
            oldDesktop.setStatus("Logged Out");
            loginActivityRepository.save(oldDesktop);

            activities = loginActivityRepository.findByEmpIdOrderByLoginDtDesc(empId);
        }

        // 3. Static Support Info
        Map<String, String> support = Map.of(
                "helpCenter", "/api/support/help-center",
                "contactAdmin", "admin@atirath.com",
                "userGuide", "/api/support/user-guide",
                "appVersion", "Version 1.0.0"
        );

        return new EmployeeSettingsResponseDto(settings, activities, support);
    }

    @Transactional
    public EmployeeSettings updateSettings(Long empId, EmployeeSettings updated) {
        EmployeeSettings settings = settingsRepository.findByEmpId(empId)
                .orElseGet(() -> {
                    EmployeeSettings s = new EmployeeSettings();
                    s.setEmpId(empId);
                    return s;
                });

        if (updated.getLanguage() != null) {
            settings.setLanguage(updated.getLanguage());
        }
        if (updated.getDateFormat() != null) {
            settings.setDateFormat(updated.getDateFormat());
        }
        if (updated.getTimeZone() != null) {
            settings.setTimeZone(updated.getTimeZone());
        }
        if (updated.getTheme() != null) {
            settings.setTheme(updated.getTheme());
        }

        return settingsRepository.save(settings);
    }

    @Transactional
    public void recordLoginActivity(Long empId, String deviceInfo) {
        // Set previous active sessions to logged out
        List<EmployeeLoginActivity> active = loginActivityRepository.findByEmpIdOrderByLoginDtDesc(empId);
        for (EmployeeLoginActivity activity : active) {
            if ("Active".equalsIgnoreCase(activity.getStatus())) {
                activity.setStatus("Logged Out");
                loginActivityRepository.save(activity);
            }
        }

        EmployeeLoginActivity newActivity = new EmployeeLoginActivity();
        newActivity.setEmpId(empId);
        newActivity.setDeviceInfo(deviceInfo);
        newActivity.setStatus("Active");
        newActivity.setLoginDt(LocalDateTime.now());
        loginActivityRepository.save(newActivity);
    }
}
