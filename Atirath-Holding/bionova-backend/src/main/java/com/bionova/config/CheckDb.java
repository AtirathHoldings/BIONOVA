package com.bionova.config;

import com.bionova.entity.Employee;
import com.bionova.entity.RoleBasedAccessControl;
import com.bionova.entity.RoleBasedEmployeeMapping;
import com.bionova.entity.ScreenMaster;
import com.bionova.repository.EmployeeRepository;
import com.bionova.repository.RoleBasedAccessControlRepository;
import com.bionova.repository.RoleBasedEmployeeMappingRepository;
import com.bionova.repository.ScreenMasterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class CheckDb implements CommandLineRunner {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private RoleBasedEmployeeMappingRepository employeeMappingRepository;

    @Autowired
    private RoleBasedAccessControlRepository rbacRepository;

    @Autowired
    private ScreenMasterRepository screenMasterRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("\n=== CHECKING DB AND RBAC ROLES ===");

        // Fix truncated base64 logo of Company 1 in the database
        try {
            jdbcTemplate.update("UPDATE company_master SET logo = ? WHERE coy_id = 1", 
                "https://daaoeapbouspxcuprsqx.supabase.co/storage/v1/object/public/images/logos/plantmaster/50605f76-cdb4-4473-9806-c74e426f733a.PNG");
            System.out.println("Updated Company 1 logo to a valid URL in company_master");
        } catch (Exception e) {
            System.err.println("Failed to update Company 1 logo: " + e.getMessage());
        }

        // Also fix Plant 1 logo if it is null/empty
        try {
            jdbcTemplate.update("UPDATE plant_master SET logo = ? WHERE plt_id = 1 AND (logo IS NULL OR logo = '')", 
                "https://daaoeapbouspxcuprsqx.supabase.co/storage/v1/object/public/images/logos/plantmaster/3e321172-0e85-4bcc-b341-21bb5d9e2689.PNG");
            System.out.println("Updated Plant 1 logo to a valid URL in plant_master");
        } catch (Exception e) {
            System.err.println("Failed to update Plant 1 logo: " + e.getMessage());
        }
        
        // Print all Screen Codes in ScreenMaster
        System.out.println("--- Screen Master entries: ---");
        List<ScreenMaster> screens = screenMasterRepository.findAll();
        for (ScreenMaster s : screens) {
            System.out.printf("Screen ID: %d, Name: %s, Code: %s, Group: %s\n", 
                s.getScreenId(), s.getScreenNm(), s.getScreenCode(), s.getGroupNm());
        }

        inspectUser("vkpraveen216@gmail.com");
        inspectUser("gaddamdeekshitha1@gmail.com");

        System.out.println("=== END OF CHECKING DB AND RBAC ROLES ===\n");
    }

    private void inspectUser(String email) {
        System.out.println("\nInspecting user: " + email);
        employeeRepository.findByEmail(email).ifPresentOrElse(emp -> {
            System.out.printf("Employee ID: %d, Name: %s %s, Status: %b\n", 
                emp.getEmpId(), emp.getFirstName(), emp.getLastName(), emp.getStatus());
            
            List<RoleBasedEmployeeMapping> mappings = employeeMappingRepository.findByEmpId(emp.getEmpId());
            if (mappings.isEmpty()) {
                System.out.println("No RBAC mappings found (User has FULL ACCESS by default)");
            } else {
                for (RoleBasedEmployeeMapping map : mappings) {
                    System.out.printf("  Mapped to Role ID: %d\n", map.getRoleId());
                    List<RoleBasedAccessControl> rbacList = rbacRepository.findByRoleId(map.getRoleId());
                    System.out.println("  RBAC permissions for Role ID " + map.getRoleId() + ":");
                    for (RoleBasedAccessControl rbac : rbacList) {
                        screenMasterRepository.findById(rbac.getScreenId()).ifPresent(screen -> {
                            System.out.printf("    Screen: %s (%s) -> View: %s, Add: %s, Edit: %s, Delete: %s\n",
                                screen.getScreenNm(), screen.getScreenCode(),
                                rbac.getViewFlg(), rbac.getAddFlg(), rbac.getEditFlg(), rbac.getDeleteFlg());
                        });
                    }
                }
            }

            // Test execution of get_user_dashboard stored procedure
            try {
                System.out.println("  Testing stored procedure execution for empId: " + emp.getEmpId());
                String result = jdbcTemplate.queryForObject("SELECT get_user_dashboard(?)", String.class, emp.getEmpId());
                System.out.println("  SUCCESS! Stored procedure returned: " + (result != null ? result.substring(0, Math.min(100, result.length())) + "..." : "null"));
            } catch (Exception e) {
                System.err.println("  FAILED to execute stored procedure: " + e.getMessage());
                e.printStackTrace();
            }

        }, () -> {
            System.out.println("Employee not found for email: " + email);
        });
    }
}
