package com.bionova;

import org.junit.jupiter.api.Test;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class QueryEmp5TasksTest {

    @Test
    public void queryEmp5Tasks() {
        String url = "jdbc:postgresql://aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true&prepareThreshold=0";
        String user = "postgres.daaoeapbouspxcuprsqx";
        String password = "Atirath@2026";

        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement()) {
            
            System.out.println("=== QUERYING get_user_dashboard(5) FROM DB ===");
            try (ResultSet rs = stmt.executeQuery("SELECT get_user_dashboard(5)::text AS data")) {
                if (rs.next()) {
                    System.out.println(rs.getString("data"));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
