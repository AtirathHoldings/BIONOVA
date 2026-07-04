package com.bionova.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
public class DatabaseFixer implements CommandLineRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        try {
            // Find unique constraints on checklist_master that target only chk_cd
            List<String> constraints = jdbcTemplate.queryForList(
                "SELECT con.conname FROM pg_constraint con " +
                "JOIN pg_class rel ON rel.oid = con.conrelid " +
                "WHERE rel.relname = 'checklist_master' AND con.contype = 'u' AND con.conname LIKE '%chk_cd%' " +
                "AND con.conname <> 'uq_chk_task_code'", 
                String.class
            );
            for (String constraint : constraints) {
                System.out.println("Dropping global unique constraint: " + constraint);
                jdbcTemplate.execute("ALTER TABLE checklist_master DROP CONSTRAINT IF EXISTS " + constraint);
            }

            // Also check pg_indexes just in case a unique index was created directly
            List<String> indexes = jdbcTemplate.queryForList(
                "SELECT indexname FROM pg_indexes " +
                "WHERE tablename = 'checklist_master' AND indexdef LIKE '%chk_cd%' AND indexdef LIKE '%UNIQUE%' " +
                "AND indexname NOT LIKE '%uq_chk_task_code%'",
                String.class
            );
            for (String index : indexes) {
                System.out.println("Dropping global unique index: " + index);
                jdbcTemplate.execute("DROP INDEX IF EXISTS " + index);
            }
        } catch (Exception e) {
            System.err.println("Error running database fixer: " + e.getMessage());
        }
    }
}
