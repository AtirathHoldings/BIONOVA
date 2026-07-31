package com.bionova;

import org.junit.jupiter.api.Test;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class CheckFunctionsTest {

    @Test
    public void inspectStoredFunctions() {
        String url = "jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true&prepareThreshold=0";
        String user = "postgres.daaoeapbouspxcuprsqx";
        String password = "Atirath@2026";

        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement()) {
            
            System.out.println("=== get_user_dashboard definition ===");
            try (ResultSet rs = stmt.executeQuery("SELECT prosrc FROM pg_proc WHERE proname = 'get_user_dashboard'")) {
                if (rs.next()) {
                    System.out.println(rs.getString("prosrc"));
                } else {
                    System.out.println("Function get_user_dashboard not found!");
                }
            }

            System.out.println("\n=== get_my_tasks_data definition ===");
            try (ResultSet rs = stmt.executeQuery("SELECT prosrc FROM pg_proc WHERE proname = 'get_my_tasks_data'")) {
                if (rs.next()) {
                    System.out.println(rs.getString("prosrc"));
                } else {
                    System.out.println("Function get_my_tasks_data not found!");
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
