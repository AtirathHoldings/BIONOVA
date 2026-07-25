package com.bionova;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import java.nio.file.Files;
import java.nio.file.Paths;

@SpringBootTest
public class UpdateDbFunctionTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    public void applySqlCheckScript() throws Exception {
        String sql = Files.readString(Paths.get("sql_check.sql"));
        jdbcTemplate.execute(sql);
        System.out.println("Applied sql_check.sql to Supabase DB successfully!");
        String json = jdbcTemplate.queryForObject("SELECT get_user_dashboard(5)::text", String.class);
        System.out.println("=== DASHBOARD JSON OUTPUT ===");
        System.out.println(json);
    }
}
