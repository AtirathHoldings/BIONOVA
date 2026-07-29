package com.bionova;

import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

public class UpdatePasswordTest {

    @Test
    public void updateEmployeePassword() {
        String rawPassword = "Aathika@123";
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        String hashedPassword = encoder.encode(rawPassword);

        System.out.println("=========================================");
        System.out.println("Raw Password: " + rawPassword);
        System.out.println("Hashed Password: " + hashedPassword);
        System.out.println("=========================================");

        String url = "jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true&prepareThreshold=0";
        String user = "postgres.daaoeapbouspxcuprsqx";
        String password = "Atirath@2026";

        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            // Upsert into employee_password_master for emp_id = 29
            String sql = "INSERT INTO employee_password_master (emp_id, emp_password) VALUES (29, ?) " +
                         "ON CONFLICT (emp_id) DO UPDATE SET emp_password = EXCLUDED.emp_password";
            try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
                pstmt.setString(1, hashedPassword);
                int rows = pstmt.executeUpdate();
                System.out.println("SUCCESS: Updated password in employee_password_master for emp_id 29 (Aathika Farheen). Rows affected: " + rows);
            }

            // Verify the updated row
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT e.emp_id, e.emp_code, e.fst_nm, e.email, p.emp_password FROM employee_master e JOIN employee_password_master p ON e.emp_id = p.emp_id WHERE e.emp_id = 29")) {
                if (rs.next()) {
                    System.out.println("VERIFIED IN DB: ID=" + rs.getInt("emp_id") +
                                       ", Code=" + rs.getString("emp_code") +
                                       ", Name=" + rs.getString("fst_nm") +
                                       ", Email=" + rs.getString("email") +
                                       ", Hash=" + rs.getString("emp_password"));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
