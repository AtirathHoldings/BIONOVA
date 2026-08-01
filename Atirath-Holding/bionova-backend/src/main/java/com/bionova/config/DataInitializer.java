package com.bionova.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;


@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("--- Running DataInitializer ---");

        // States and admin user are added manually via the app.

        // 3. Initialize PostgreSQL triggers for automatic status change logging (database level + application level)
        System.out.println("Initializing status change triggers in PostgreSQL...");
        try {
            jdbcTemplate.execute(
                "CREATE OR REPLACE FUNCTION log_status_change_trigger() " +
                "RETURNS TRIGGER AS $$ " +
                "BEGIN " +
                "    IF (TG_OP = 'UPDATE') THEN " +
                "        IF (TG_TABLE_NAME = 'task_live_master') THEN " +
                "            IF (OLD.task_sts IS DISTINCT FROM NEW.task_sts) THEN " +
                "                INSERT INTO activity_log_transaction (entity_typ, entity_id, status_from, status_to, log_dt) " +
                "                VALUES ('TASK', OLD.task_id, " +
                "                        COALESCE((SELECT status_nm FROM task_status_master WHERE status_id = OLD.task_sts), 'N/A'), " +
                "                        (SELECT status_nm FROM task_status_master WHERE status_id = NEW.task_sts), " +
                "                        CURRENT_TIMESTAMP); " +
                "            END IF; " +
                "        ELSIF (TG_TABLE_NAME = 'milestone_live_master') THEN " +
                "            IF (OLD.mlstn_sts IS DISTINCT FROM NEW.mlstn_sts) THEN " +
                "                INSERT INTO activity_log_transaction (entity_typ, entity_id, status_from, status_to, log_dt) " +
                "                VALUES ('MILESTONE', OLD.m_id, COALESCE(OLD.mlstn_sts, 'N/A'), NEW.mlstn_sts, CURRENT_TIMESTAMP); " +
                "            END IF; " +
                "        ELSIF (TG_TABLE_NAME = 'project_live_master') THEN " +
                "            IF (OLD.prj_sts IS DISTINCT FROM NEW.prj_sts) THEN " +
                "                INSERT INTO activity_log_transaction (entity_typ, entity_id, status_from, status_to, log_dt) " +
                "                VALUES ('PROJECT', OLD.prj_id, COALESCE(OLD.prj_sts, 'N/A'), NEW.prj_sts, CURRENT_TIMESTAMP); " +
                "            END IF; " +
                "        END IF; " +
                "    END IF; " +
                "    RETURN NEW; " +
                "END; " +
                "$$ LANGUAGE plpgsql;"
            );

            jdbcTemplate.execute(
                "DROP TRIGGER IF EXISTS trigger_log_project_status ON project_live_master; " +
                "CREATE TRIGGER trigger_log_project_status " +
                "AFTER UPDATE ON project_live_master " +
                "FOR EACH ROW " +
                "EXECUTE FUNCTION log_status_change_trigger();"
            );

            jdbcTemplate.execute(
                "DROP TRIGGER IF EXISTS trigger_log_milestone_status ON milestone_live_master; " +
                "CREATE TRIGGER trigger_log_milestone_status " +
                "AFTER UPDATE ON milestone_live_master " +
                "FOR EACH ROW " +
                "EXECUTE FUNCTION log_status_change_trigger();"
            );

            jdbcTemplate.execute(
                "DROP TRIGGER IF EXISTS trigger_log_task_status ON task_live_master; " +
                "CREATE TRIGGER trigger_log_task_status " +
                "AFTER UPDATE ON task_live_master " +
                "FOR EACH ROW " +
                "EXECUTE FUNCTION log_status_change_trigger();"
            );
            System.out.println("Status change triggers initialized successfully.");
        } catch (Exception e) {
            System.err.println("Failed to create status change database triggers: " + e.getMessage());
        }

        // 4. Migrate data from old table dept_coy_plt_map to new table dept_company_plt_map if empty
        try {
            Integer oldTableExists = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM information_schema.tables WHERE table_name='dept_coy_plt_map' AND table_schema='public'", Integer.class);
            if (oldTableExists != null && oldTableExists > 0) {
                Integer newCount = jdbcTemplate.queryForObject("SELECT count(*) FROM dept_company_plt_map", Integer.class);
                if (newCount == null || newCount == 0) {
                    System.out.println("Copying mapping records from dept_coy_plt_map to dept_company_plt_map...");
                    jdbcTemplate.execute(
                        "INSERT INTO dept_company_plt_map (map_id, dept_id, coy_id, plt_id, sts) " +
                        "SELECT map_id, dept_id, coy_id, plt_id, sts FROM dept_coy_plt_map " +
                        "ON CONFLICT (map_id) DO NOTHING"
                    );
                    try {
                        jdbcTemplate.execute("SELECT setval(pg_get_serial_sequence('dept_company_plt_map', 'map_id'), COALESCE(MAX(map_id), 1)) FROM dept_company_plt_map;");
                    } catch (Exception seqEx) {
                        System.err.println("Could not reset mapId sequence: " + seqEx.getMessage());
                    }
                    System.out.println("Mappings copied successfully.");
                }
            }
        } catch (Exception e) {
            System.err.println("Could not copy mappings from old table to new table: " + e.getMessage());
        }

        // 5. Ensure task_draft_master task_sts and priority columns are INTEGER in PostgreSQL
        try {
            jdbcTemplate.execute(
                "ALTER TABLE task_draft_master " +
                "ALTER COLUMN task_sts TYPE integer " +
                "USING ( " +
                "  CASE " +
                "    WHEN task_sts::text ~ '^[0-9]+$' THEN task_sts::text::integer " +
                "    WHEN UPPER(task_sts::text) = 'DRAFT' THEN 1 " +
                "    WHEN UPPER(task_sts::text) = 'OPEN' THEN 2 " +
                "    WHEN UPPER(task_sts::text) IN ('WIP', 'IN_PROGRESS', 'IN PROGRESS', 'UNDER_REVIEW', 'REWORK', 'REASSIGN') THEN 3 " +
                "    WHEN UPPER(task_sts::text) IN ('CLOSED', 'COMPLETED') THEN 4 " +
                "    WHEN UPPER(task_sts::text) = 'HOLD' THEN 5 " +
                "    ELSE 1 " +
                "  END " +
                ");"
            );
        } catch (Exception e) {
            System.out.println("task_draft_master.task_sts column migration note: " + e.getMessage());
        }

        try {
            jdbcTemplate.execute(
                "ALTER TABLE task_draft_master " +
                "ALTER COLUMN priority TYPE integer " +
                "USING ( " +
                "  CASE " +
                "    WHEN priority::text ~ '^[0-9]+$' THEN priority::text::integer " +
                "    WHEN UPPER(priority::text) = 'LOW' THEN 1 " +
                "    WHEN UPPER(priority::text) IN ('MEDIUM', 'NORMAL') THEN 2 " +
                "    WHEN UPPER(priority::text) = 'HIGH' THEN 3 " +
                "    WHEN UPPER(priority::text) = 'CRITICAL' THEN 4 " +
                "    WHEN UPPER(priority::text) IN ('ATMOST CRITICAL', 'AT MOST CRITICAL', 'ATMOST_CRITICAL') THEN 5 " +
                "    ELSE 2 " +
                "  END " +
                ");"
            );
        } catch (Exception e) {
            System.out.println("task_draft_master.priority column migration note: " + e.getMessage());
        }
    }
}
