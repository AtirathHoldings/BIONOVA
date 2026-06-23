package com.bionova.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("--- Running DataInitializer ---");

        // 1. Initialize states if empty
        Integer stateCount = jdbcTemplate.queryForObject("SELECT count(*) FROM state_master", Integer.class);
        if (stateCount == null || stateCount == 0) {
            System.out.println("Initializing state_master table...");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('MH', 'WEST', 'Maharashtra')");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('GJ', 'WEST', 'Gujarat')");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('KA', 'SOUTH', 'Karnataka')");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('TN', 'SOUTH', 'Tamil Nadu')");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('TS', 'SOUTH', 'Telangana')");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('DL', 'NORTH', 'Delhi')");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('WB', 'EAST', 'West Bengal')");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('RJ', 'NORTH', 'Rajasthan')");
            jdbcTemplate.execute("INSERT INTO state_master (st_cd, zn_nm, st_nm) VALUES ('AP', 'SOUTH', 'Andhra Pradesh')");
            System.out.println("States initialized successfully.");
        } else {
            System.out.println("state_master already has " + stateCount + " records.");
        }

        // 2. Initialize admin user if not exists
        List<Map<String, Object>> employees = jdbcTemplate.queryForList(
                "SELECT emp_id FROM employee_master WHERE email = ?", "siva@atirath.com");
        if (employees.isEmpty()) {
            System.out.println("Admin user siva@atirath.com not found. Creating...");
            // Insert into employee_master
            jdbcTemplate.update(
                "INSERT INTO employee_master (emp_code, fst_nm, lst_nm, gender, dob, email, mob_num, bld_grp, address, w_loc, sts, role) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                "EMP01", "Siva", "Kumar", "MALE", java.sql.Date.valueOf("1990-01-01"), "siva@atirath.com", "9999999999", "O+", "Atirath Office", "Office", true, "admin"
            );

            // Get generated emp_id
            Long empId = jdbcTemplate.queryForObject(
                "SELECT emp_id FROM employee_master WHERE email = ?", Long.class, "siva@atirath.com");

            String hashedPassword = new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode("Siva@123");
            // Insert into employee_password_master
            jdbcTemplate.update(
                "INSERT INTO employee_password_master (emp_id, emp_password) VALUES (?, ?)",
                empId, hashedPassword
            );
            System.out.println("Admin user siva@atirath.com created successfully with emp_id = " + empId);
        } else {
            System.out.println("Admin user siva@atirath.com already exists.");
            // Always re-hash the password on startup to ensure it matches "Siva@123"
            String hashed = new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder().encode("Siva@123");
            jdbcTemplate.update(
                "UPDATE employee_password_master SET emp_password = ? WHERE emp_id = (SELECT emp_id FROM employee_master WHERE email = ?)",
                hashed, "siva@atirath.com"
            );
            System.out.println("Admin password refreshed successfully.");
        }
    }
}
