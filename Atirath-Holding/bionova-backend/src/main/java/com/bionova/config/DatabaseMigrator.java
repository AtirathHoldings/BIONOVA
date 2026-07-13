package com.bionova.config;

import org.springframework.beans.BeansException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.config.BeanFactoryPostProcessor;
import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@Component("databaseMigrator")
public class DatabaseMigrator implements InitializingBean {

    @Autowired
    private DataSource dataSource;

    @Override
    public void afterPropertiesSet() throws Exception {
        System.out.println("--- Running DatabaseMigrator BEFORE Hibernate starts ---");
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {

            // 1. Create and populate task_status_master
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS task_status_master (" +
                "    status_id INTEGER PRIMARY KEY," +
                "    status_nm VARCHAR(20) NOT NULL UNIQUE" +
                ")"
            );

            // Check if we need to migrate old status values
            boolean needsMigration = false;
            try (ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM task_status_master WHERE status_nm IN ('ASSIGNED', 'SUBMIT_REVIEW')")) {
                if (rs.next() && rs.getInt(1) > 0) {
                    needsMigration = true;
                }
            } catch (Exception e) {
                // Table might not exist or be empty yet
            }

            if (needsMigration) {
                System.out.println("Migrating old task status values to new order (lock-free)...");
                // 1. Update task_sts column in referencing tables (using existing valid IDs 1-7)
                String[] statusReferencingTables = {"task_live_master", "task_draft_master", "employee_individual_task_master"};
                for (String tbl : statusReferencingTables) {
                    try {
                        stmt.execute(
                            "UPDATE " + tbl + " SET task_sts = CASE " +
                            "  WHEN task_sts = 1 THEN 1 " + // DRAFT -> DRAFT
                            "  WHEN task_sts = 2 THEN 2 " + // ASSIGNED -> OPEN
                            "  WHEN task_sts = 3 THEN 2 " + // OPEN -> OPEN
                            "  WHEN task_sts = 4 THEN 3 " + // WIP -> WIP
                            "  WHEN task_sts = 5 THEN 4 " + // SUBMIT_REVIEW -> UNDER_REVIEW
                            "  WHEN task_sts = 6 THEN 4 " + // UNDER_REVIEW -> UNDER_REVIEW
                            "  WHEN task_sts = 7 THEN 5 " + // COMPLETED -> COMPLETED
                            "  WHEN task_sts = 8 THEN 6 " + // REASSIGN -> REASSIGN
                            "  WHEN task_sts = 9 THEN 7 " + // REWORK -> REWORK
                            "  ELSE 2 " +
                            "END"
                        );
                    } catch (Exception ex) {
                        System.err.println("Failed to update status in " + tbl + ": " + ex.getMessage());
                    }
                }

                // 1.5. Append _TEMP to existing status names to avoid unique constraint violations during rename
                try {
                    stmt.execute("UPDATE task_status_master SET status_nm = status_nm || '_TEMP'");
                } catch (Exception ex) {
                    System.err.println("Failed to rename status names temporarily: " + ex.getMessage());
                }

                // 2. Delete old status IDs >= 8 since they are no longer referenced
                try {
                    stmt.execute("DELETE FROM task_status_master WHERE status_id >= 8");
                } catch (Exception ex) {
                    System.err.println("Failed to delete old status IDs: " + ex.getMessage());
                }
            }

            stmt.execute("INSERT INTO task_status_master (status_id, status_nm) VALUES " +
                "(1, 'DRAFT'), (2, 'OPEN'), (3, 'WIP'), (4, 'UNDER_REVIEW'), " +
                "(5, 'COMPLETED'), (6, 'REASSIGN'), (7, 'REWORK'), (8, 'OVER_DUE') " +
                "ON CONFLICT (status_id) DO UPDATE SET status_nm = EXCLUDED.status_nm");
            System.out.println("task_status_master initialized.");

            // 1c. Ensure screen_master has screen_code column and populate it
            // This is critical for RBAC enforcement — RbacGuardFilter maps
            // URL paths → screen_code → screenId → checks viewFlg
            try {
                // Add screen_code column if missing
                stmt.execute(
                    "ALTER TABLE screen_master ADD COLUMN IF NOT EXISTS screen_code VARCHAR(50) UNIQUE"
                );

                // Populate screen_code based on screen_nm / group_nm patterns
                // Only updates rows where screen_code is still NULL (idempotent)
                String[] screenCodeUpdates = {
                    // User Management
                    "UPDATE screen_master SET screen_code = 'USER_MGMT' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%user%' OR LOWER(screen_nm) LIKE '%employee%' " +
                    "  OR LOWER(screen_nm) LIKE '%staff%' OR LOWER(group_nm) LIKE '%user%')",

                    // Company Management
                    "UPDATE screen_master SET screen_code = 'COMPANY_MGMT' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%company%' OR LOWER(screen_nm) LIKE '%organisation%' " +
                    "  OR LOWER(group_nm) LIKE '%company%')",

                    // Plant Management
                    "UPDATE screen_master SET screen_code = 'PLANT_MGMT' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%plant%' OR LOWER(group_nm) LIKE '%plant%')",

                    // Department / Org mapping
                    "UPDATE screen_master SET screen_code = 'DEPT_COY_PLT' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%department%' OR LOWER(screen_nm) LIKE '%dept%' " +
                    "  OR LOWER(group_nm) LIKE '%dept%')",

                    // Role / Access Management
                    "UPDATE screen_master SET screen_code = 'ROLE_MGMT' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%role%' OR LOWER(screen_nm) LIKE '%access%' " +
                    "  OR LOWER(screen_nm) LIKE '%rbac%' OR LOWER(screen_nm) LIKE '%permission%' " +
                    "  OR LOWER(group_nm) LIKE '%role%' OR LOWER(group_nm) LIKE '%access%')",

                    // Project Draft
                    "UPDATE screen_master SET screen_code = 'PROJECT_DRAFT' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%project%draft%' OR LOWER(screen_nm) LIKE '%draft%project%' " +
                    "  OR (LOWER(screen_nm) LIKE '%draft%' AND LOWER(group_nm) LIKE '%project%'))",

                    // Project Live
                    "UPDATE screen_master SET screen_code = 'PROJECT_LIVE' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%project%live%' OR LOWER(screen_nm) LIKE '%live%project%' " +
                    "  OR (LOWER(screen_nm) LIKE '%project%' AND LOWER(group_nm) LIKE '%project%'))",

                    // Process Config
                    "UPDATE screen_master SET screen_code = 'PROCESS_CONFIG' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%process%config%' OR LOWER(screen_nm) LIKE '%config%process%')",

                    // Process Management
                    "UPDATE screen_master SET screen_code = 'PROCESS_MGMT' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%process%' OR LOWER(group_nm) LIKE '%process%')",

                    // Checklist
                    "UPDATE screen_master SET screen_code = 'CHECKLIST' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%checklist%' OR LOWER(screen_nm) LIKE '%check list%')",

                    // Team Members
                    "UPDATE screen_master SET screen_code = 'TEAM_MEMBERS' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%team%' OR LOWER(screen_nm) LIKE '%member%')",

                    // Calendar
                    "UPDATE screen_master SET screen_code = 'CALENDAR_MASTER' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%calendar%' OR LOWER(group_nm) LIKE '%calendar%')",

                    // Admin Dashboard
                    "UPDATE screen_master SET screen_code = 'ADMIN_DASHBOARD' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%admin%dashboard%' OR LOWER(screen_nm) LIKE '%admin%report%' " +
                    "  OR (LOWER(screen_nm) LIKE '%admin%' AND LOWER(group_nm) LIKE '%dashboard%'))",

                    // User Dashboard
                    "UPDATE screen_master SET screen_code = 'USER_DASHBOARD' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%user%dashboard%' OR LOWER(screen_nm) LIKE '%my%task%' " +
                    "  OR (LOWER(screen_nm) LIKE '%dashboard%' AND LOWER(group_nm) LIKE '%user%'))",

                    // Project Dashboard
                    "UPDATE screen_master SET screen_code = 'PROJECT_DASHBOARD' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%project%dashboard%' " +
                    "  OR (LOWER(screen_nm) LIKE '%dashboard%' AND LOWER(group_nm) LIKE '%project%'))",

                    // Gantt Chart
                    "UPDATE screen_master SET screen_code = 'GANTT_CHART' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%gantt%' OR LOWER(screen_nm) LIKE '%chart%')",

                    // Forecasting
                    "UPDATE screen_master SET screen_code = 'FORECASTING' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%forecast%')",

                    // Project Access
                    "UPDATE screen_master SET screen_code = 'PROJECT_ACCESS' " +
                    "WHERE screen_code IS NULL AND (" +
                    "  LOWER(screen_nm) LIKE '%project%access%' OR LOWER(screen_nm) LIKE '%access%project%')"
                };

                for (String sql : screenCodeUpdates) {
                    try { stmt.execute(sql); } catch (Exception ex) {
                        System.err.println("screen_code update failed: " + ex.getMessage());
                    }
                }
                System.out.println("screen_master screen_code values initialized.");
            } catch (Exception e) {
                System.err.println("Failed to initialize screen_code in screen_master: " + e.getMessage());
            }

            // 1b. Create and populate task_priority_master
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS task_priority_master (" +
                "    priority_id INTEGER PRIMARY KEY," +
                "    priority_nm VARCHAR(20) NOT NULL UNIQUE" +
                ")"
            );
            stmt.execute("INSERT INTO task_priority_master (priority_id, priority_nm) VALUES " +
                "(1, 'LOW'), (2, 'NORMAL'), (3, 'MEDIUM'), (4, 'HIGH'), " +
                "(5, 'CRITICAL') ON CONFLICT (priority_id) DO NOTHING");
            System.out.println("task_priority_master initialized.");

            // Drop global unique constraints on mlstn_cd and task_cd to allow same codes in different projects
            try {
                stmt.execute("ALTER TABLE milestone_draft_master DROP CONSTRAINT IF EXISTS milestone_draft_master_mlstn_cd_key");
                stmt.execute("ALTER TABLE milestone_live_master DROP CONSTRAINT IF EXISTS milestone_live_master_mlstn_cd_key");
                stmt.execute("ALTER TABLE task_draft_master DROP CONSTRAINT IF EXISTS task_draft_master_task_cd_key");
                stmt.execute("ALTER TABLE task_live_master DROP CONSTRAINT IF EXISTS task_live_master_task_cd_key");
                stmt.execute("ALTER TABLE employee_individual_task_master DROP CONSTRAINT IF EXISTS employee_individual_task_master_task_cd_key");
                System.out.println("Global unique constraints on mlstn_cd and task_cd dropped.");
            } catch (Exception e) {
                System.err.println("Could not drop global unique constraints: " + e.getMessage());
            }

            // 2. Migrate existing varchar columns to integer
            String[] tables = {"task_live_master", "task_draft_master", "employee_individual_task_master"};
            for (String table : tables) {
                // Check if table exists
                try (ResultSet rs = conn.getMetaData().getTables(null, null, table, null)) {
                    if (!rs.next()) {
                        continue;
                    }
                }

                // Check if task_sts column exists and is varchar
                boolean isVarchar = false;
                try (ResultSet rs = conn.getMetaData().getColumns(null, null, table, "task_sts")) {
                    if (rs.next()) {
                        String type = rs.getString("TYPE_NAME");
                        if (type != null && (type.toLowerCase().contains("char") || type.toLowerCase().contains("text"))) {
                            isVarchar = true;
                        }
                    }
                }

                if (isVarchar) {
                    System.out.println("Migrating column task_sts in " + table + " to INTEGER...");
                    try {
                        stmt.execute("ALTER TABLE " + table + " DROP CONSTRAINT IF EXISTS " + table + "_task_sts_check");
                    } catch (Exception ce) {}
                    try {
                        stmt.execute("ALTER TABLE " + table + " DROP CONSTRAINT IF EXISTS " + table + "_priority_check");
                    } catch (Exception ce) {}
                    try {
                        stmt.execute("ALTER TABLE " + table + " ALTER COLUMN task_sts DROP DEFAULT");
                    } catch (Exception ce) {}

                    stmt.execute(
                        "ALTER TABLE " + table + " ALTER COLUMN task_sts TYPE integer USING " +
                        "CASE " +
                        "  WHEN UPPER(task_sts) = 'DRAFT' THEN 1 " +
                        "  WHEN UPPER(task_sts) = 'ASSIGNED' THEN 2 " +
                        "  WHEN UPPER(task_sts) = 'OPEN' THEN 2 " +
                        "  WHEN UPPER(task_sts) = 'WIP' THEN 3 " +
                        "  WHEN UPPER(task_sts) = 'SUBMIT_REVIEW' THEN 4 " +
                        "  WHEN UPPER(task_sts) = 'UNDER_REVIEW' THEN 4 " +
                        "  WHEN UPPER(task_sts) = 'COMPLETED' THEN 5 " +
                        "  WHEN UPPER(task_sts) = 'REASSIGN' THEN 6 " +
                        "  WHEN UPPER(task_sts) = 'REWORK' THEN 7 " +
                        "  WHEN UPPER(task_sts) = 'OVER_DUE' OR UPPER(task_sts) = 'OVER DUE' THEN 8 " +
                        "  ELSE 2 " +
                        "END"
                    );
                    System.out.println("Successfully migrated task_sts in " + table + " to INTEGER.");
                }
            }

            // 2b. Migrate priority column in employee_individual_task_master to integer
            String priorityTable = "employee_individual_task_master";
            try {
                boolean tableExists = false;
                try (ResultSet rs = conn.getMetaData().getTables(null, null, priorityTable, null)) {
                    if (rs.next()) {
                        tableExists = true;
                    }
                }
                if (tableExists) {
                    boolean priorityIsVarchar = false;
                    try (ResultSet rs = conn.getMetaData().getColumns(null, null, priorityTable, "priority")) {
                        if (rs.next()) {
                            String type = rs.getString("TYPE_NAME");
                            if (type != null && (type.toLowerCase().contains("char") || type.toLowerCase().contains("text"))) {
                                priorityIsVarchar = true;
                            }
                        }
                    }

                    if (priorityIsVarchar) {
                        System.out.println("Migrating column priority in " + priorityTable + " to INTEGER...");
                        try {
                            stmt.execute("ALTER TABLE " + priorityTable + " DROP CONSTRAINT IF EXISTS " + priorityTable + "_priority_check");
                        } catch (Exception ce) {}
                        try {
                            stmt.execute("ALTER TABLE " + priorityTable + " DROP CONSTRAINT IF EXISTS employee_individual_task_master_priority_check");
                        } catch (Exception ce) {}
                        try {
                            stmt.execute("ALTER TABLE " + priorityTable + " ALTER COLUMN priority DROP DEFAULT");
                        } catch (Exception ce) {}

                        stmt.execute(
                            "ALTER TABLE " + priorityTable + " ALTER COLUMN priority TYPE integer USING " +
                            "CASE " +
                            "  WHEN UPPER(priority) = 'LOW' THEN 1 " +
                            "  WHEN UPPER(priority) = 'NORMAL' THEN 2 " +
                            "  WHEN UPPER(priority) = 'MEDIUM' THEN 3 " +
                            "  WHEN UPPER(priority) = 'HIGH' THEN 4 " +
                            "  WHEN UPPER(priority) = 'CRITICAL' THEN 5 " +
                            "  ELSE 1 " +
                            "END"
                        );
                        System.out.println("Successfully migrated priority in " + priorityTable + " to INTEGER.");
                    }
                }
            } catch (Exception e) {
                System.err.println("Failed to migrate column priority in table " + priorityTable + ": " + e.getMessage());
            }

            // 2c. Migrate prj_prty column in project_live_master and project_draft_master to integer
            String[] projectTables = {"project_live_master", "project_draft_master"};
            for (String table : projectTables) {
                try {
                    boolean tableExists = false;
                    try (ResultSet rs = conn.getMetaData().getTables(null, null, table, null)) {
                        if (rs.next()) {
                            tableExists = true;
                        }
                    }
                    if (tableExists) {
                        boolean prjPrtyIsVarchar = false;
                        try (ResultSet rs = conn.getMetaData().getColumns(null, null, table, "prj_prty")) {
                            if (rs.next()) {
                                String type = rs.getString("TYPE_NAME");
                                if (type != null && (type.toLowerCase().contains("char") || type.toLowerCase().contains("text"))) {
                                    prjPrtyIsVarchar = true;
                                }
                            }
                        }

                        if (prjPrtyIsVarchar) {
                            System.out.println("Migrating column prj_prty in " + table + " to INTEGER...");
                            try {
                                stmt.execute("ALTER TABLE " + table + " DROP CONSTRAINT IF EXISTS " + table + "_prj_prty_check");
                            } catch (Exception ce) {}
                            try {
                                stmt.execute("ALTER TABLE " + table + " DROP CONSTRAINT IF EXISTS " + table + "_prj_prty_check1");
                            } catch (Exception ce) {}
                            try {
                                stmt.execute("ALTER TABLE " + table + " DROP CONSTRAINT IF EXISTS project_live_master_prj_prty_check");
                            } catch (Exception ce) {}
                            try {
                                stmt.execute("ALTER TABLE " + table + " DROP CONSTRAINT IF EXISTS project_draft_master_prj_prty_check");
                            } catch (Exception ce) {}
                            try {
                                stmt.execute("ALTER TABLE " + table + " ALTER COLUMN prj_prty DROP DEFAULT");
                            } catch (Exception ce) {}

                            stmt.execute(
                                "ALTER TABLE " + table + " ALTER COLUMN prj_prty TYPE integer USING " +
                                "CASE " +
                                "  WHEN UPPER(prj_prty) = 'LOW' THEN 1 " +
                                "  WHEN UPPER(prj_prty) = 'NORMAL' THEN 2 " +
                                "  WHEN UPPER(prj_prty) = 'MEDIUM' THEN 3 " +
                                "  WHEN UPPER(prj_prty) = 'HIGH' THEN 4 " +
                                "  WHEN UPPER(prj_prty) = 'CRITICAL' THEN 5 " +
                                "  ELSE 2 " +
                                "END"
                            );
                            System.out.println("Successfully migrated prj_prty in " + table + " to INTEGER.");
                        }
                    }
                } catch (Exception e) {
                    System.err.println("Failed to migrate column prj_prty in table " + table + ": " + e.getMessage());
                }
            }

            // 2d. Create/Update get_user_dashboard SQL function
            try {
                System.out.println("Creating/Updating get_user_dashboard stored procedure...");
                stmt.execute(
                    "CREATE OR REPLACE FUNCTION get_user_dashboard(p_emp_id BIGINT) " +
                    "RETURNS jsonb " +
                    "LANGUAGE plpgsql " +
                    "SECURITY DEFINER " +
                    "AS $$ " +
                    "DECLARE " +
                    "  v_today          DATE := CURRENT_DATE; " +
                    "  v_emp            RECORD; " +
                    "  v_full_name      TEXT; " +
                    "  v_total_tasks    INT := 0; " +
                    "  v_completed      INT := 0; " +
                    "  v_overdue        INT := 0; " +
                    "  v_due_today      INT := 0; " +
                    "  v_wip            INT := 0; " +
                    "  v_under_review   INT := 0; " +
                    "  v_open           INT := 0; " +
                    "  v_reassigned     INT := 0; " +
                    "  v_rework         INT := 0; " +
                    "  v_draft          INT := 0; " +
                    "  v_my_prj_count   BIGINT := 0; " +
                    "  v_todo_list      jsonb; " +
                    "  v_upcoming       jsonb; " +
                    "  v_my_projects    jsonb; " +
                    "  v_metrics_trends jsonb; " +
                    "  v_recent_activity jsonb; " +
                    "  v_performance    jsonb; " +
                    "  v_productivity   INT := 100; " +
                    "  v_quality        INT := 100; " +
                    "BEGIN " +
                    "  /* 1. Employee Profile Details */ " +
                    "  SELECT em.emp_id, em.fst_nm, em.lst_nm, em.photo_url, " +
                    "         dm.desig_nm, dept.dept_nm " +
                    "  INTO v_emp " +
                    "  FROM employee_master em " +
                    "  LEFT JOIN designation_master dm   ON dm.desig_id = em.desig_id " +
                    "  LEFT JOIN department_master  dept ON dept.dept_id = em.dept_id " +
                    "  WHERE em.emp_id = p_emp_id; " +
                    " " +
                    "  v_full_name := TRIM(COALESCE(v_emp.fst_nm,'')||' '||COALESCE(v_emp.lst_nm,'')); " +
                    " " +
                    "  /* 2. Task Counts from BOTH project tasks and individual assignments using Temporary Table */ " +
                    "  DROP TABLE IF EXISTS temp_all_tasks; " +
                    "  CREATE TEMPORARY TABLE temp_all_tasks ON COMMIT DROP AS " +
                    "    SELECT " +
                    "      t.task_id, " +
                    "      t.task_nm, " +
                    "      t.st_dt, " +
                    "      t.end_dt, " +
                    "      t.act_cmp_dt, " +
                    "      t.no_of_days, " +
                    "      t.task_sts, " +
                    "      tsm.status_nm, " +
                    "      COALESCE(p.prj_cd || ' - ' || m.mlstn_ttl, '') AS project_info, " +
                    "      COALESCE(p.prj_cd, '') AS prj_cd, " +
                    "      CASE " +
                    "        WHEN t.emp_id = p_emp_id THEN 'Executor' " +
                    "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 1) THEN 'Reviewer' " +
                    "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 2) THEN 'Approver' " +
                    "        ELSE 'Executor' " +
                    "      END AS user_badge, " +
                    "      pm.priority_nm, " +
                    "      'PROJECT' AS task_source " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "    )) " +
                    " " +
                    "    UNION ALL " +
                    " " +
                    "    SELECT " +
                    "      t.emp_task_id AS task_id, " +
                    "      t.task_nm, " +
                    "      t.st_dt, " +
                    "      t.end_dt, " +
                    "      CASE WHEN tsm.status_nm = 'COMPLETED' THEN t.end_dt ELSE NULL END AS act_cmp_dt, " +
                    "      (t.end_dt - t.st_dt) AS no_of_days, " +
                    "      t.task_sts, " +
                    "      tsm.status_nm, " +
                    "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS project_info, " +
                    "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS prj_cd, " +
                    "      CASE " +
                    "        WHEN t.emp_id = p_emp_id THEN 'Executor' " +
                    "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 1) THEN 'Reviewer' " +
                    "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 2) THEN 'Approver' " +
                    "        ELSE 'Executor' " +
                    "      END AS user_badge, " +
                    "      pm.priority_nm, " +
                    "      'INDIVIDUAL' AS task_source " +
                    "    FROM employee_individual_task_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( " +
                    "      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL " +
                    "    )) AND COALESCE(t.sts, true) = true " +
                    "  ; " +
                    "  SELECT " +
                    "    COUNT(*), " +
                    "    COUNT(*) FILTER (WHERE status_nm = 'COMPLETED'), " +
                    "    COUNT(*) FILTER (WHERE status_nm = 'OVER_DUE' OR (status_nm <> 'COMPLETED' AND end_dt IS NOT NULL AND end_dt < v_today)), " +
                    "    COUNT(*) FILTER (WHERE status_nm <> 'COMPLETED' AND end_dt = v_today), " +
                    "    COUNT(*) FILTER (WHERE status_nm = 'WIP'), " +
                    "    COUNT(*) FILTER (WHERE status_nm = 'UNDER_REVIEW'), " +
                    "    COUNT(*) FILTER (WHERE status_nm = 'OPEN'), " +
                    "    COUNT(*) FILTER (WHERE status_nm = 'REASSIGN'), " +
                    "    COUNT(*) FILTER (WHERE status_nm = 'REWORK'), " +
                    "    COUNT(*) FILTER (WHERE status_nm = 'DRAFT') " +
                    "  INTO v_total_tasks, v_completed, v_overdue, v_due_today, " +
                    "       v_wip, v_under_review, v_open, v_reassigned, v_rework, v_draft " +
                    "  FROM temp_all_tasks; " +
                    " " +
                    "  /* 3. Projects Count (Only active projects) */ " +
                    "  SELECT COUNT(DISTINCT m.prj_id) INTO v_my_prj_count " +
                    "  FROM task_live_master t " +
                    "  JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "  JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "  WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "    SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "  )) AND p.prj_sts = 'LIVE'; " +
                    " " +
                    "  /* 4. To-Do List (Limit 5, ordered by end_dt) */ " +
                    "  WITH all_todo AS ( " +
                    "    SELECT " +
                    "      t.task_id, " +
                    "      t.task_nm, " +
                    "      t.st_dt, " +
                    "      t.end_dt, " +
                    "      t.task_sts, " +
                    "      tsm.status_nm, " +
                    "      COALESCE(p.prj_cd || ' - ' || m.mlstn_ttl, '') AS project_info, " +
                    "      CASE " +
                    "        WHEN t.emp_id = p_emp_id THEN 'Executor' " +
                    "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 1) THEN 'Reviewer' " +
                    "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 2) THEN 'Approver' " +
                    "        ELSE 'Executor' " +
                    "      END AS user_badge, " +
                    "      pm.priority_nm, " +
                    "      ( " +
                    "        SELECT jsonb_agg(jsonb_build_object( " +
                    "          'empId', em.emp_id, " +
                    "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), " +
                    "          'photoUrl', em.photo_url, " +
                    "          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END " +
                    "        )) " +
                    "        FROM employee_master em " +
                    "        WHERE em.emp_id = t.emp_id " +
                    "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.task_id = t.task_id AND pc.is_live = true) " +
                    "      ) AS employees " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "    )) " +
                    " " +
                    "    UNION ALL " +
                    " " +
                    "    SELECT " +
                    "      t.emp_task_id AS task_id, " +
                    "      t.task_nm, " +
                    "      t.st_dt, " +
                    "      t.end_dt, " +
                    "      t.task_sts, " +
                    "      tsm.status_nm, " +
                    "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS project_info, " +
                    "      CASE " +
                    "        WHEN t.emp_id = p_emp_id THEN 'Executor' " +
                    "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 1) THEN 'Reviewer' " +
                    "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 2) THEN 'Approver' " +
                    "        ELSE 'Executor' " +
                    "      END AS user_badge, " +
                    "      pm.priority_nm, " +
                    "      ( " +
                    "        SELECT jsonb_agg(jsonb_build_object( " +
                    "          'empId', em.emp_id, " +
                    "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), " +
                    "          'photoUrl', em.photo_url, " +
                    "          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END " +
                    "        )) " +
                    "        FROM employee_master em " +
                    "        WHERE em.emp_id = t.emp_id " +
                    "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.emp_task_id = t.emp_task_id AND pc.emp_task_id IS NOT NULL) " +
                    "      ) AS employees " +
                    "    FROM employee_individual_task_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( " +
                    "      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL " +
                    "    )) AND COALESCE(t.sts, true) = true " +
                    "  ) " +
                    "  SELECT jsonb_agg(sub) INTO v_todo_list " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'taskId', t.task_id, " +
                    "      'taskNm', t.task_nm, " +
                    "      'project', t.project_info, " +
                    "      'endDt', t.end_dt, " +
                    "      'status', t.status_nm, " +
                    "      'isOverdue', (t.status_nm = 'OVER_DUE' OR (t.status_nm <> 'COMPLETED' AND t.end_dt < v_today)), " +
                    "      'isDueToday', (t.status_nm <> 'COMPLETED' AND t.end_dt = v_today), " +
                    "      'priority', CASE COALESCE(t.priority_nm, 'MEDIUM') " +
                    "                    WHEN 'LOW' THEN 'Low' " +
                    "                    WHEN 'NORMAL' THEN 'Medium' " +
                    "                    WHEN 'MEDIUM' THEN 'Medium' " +
                    "                    WHEN 'HIGH' THEN 'High' " +
                    "                    WHEN 'CRITICAL' THEN 'High' " +
                    "                    ELSE 'Medium' " +
                    "                  END, " +
                    "      'badge', t.user_badge, " +
                    "      'employees', COALESCE(t.employees, '[]'::jsonb) " +
                    "    ) AS sub " +
                    "    FROM all_todo t " +
                    "    WHERE t.status_nm <> 'COMPLETED' AND t.st_dt <= v_today " +
                    "    ORDER BY t.end_dt ASC NULLS LAST " +
                    "    LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  /* 5. Upcoming Tasks (Limit 5, ordered by end_dt) */ " +
                    "  WITH all_upcoming AS ( " +
                    "    SELECT " +
                    "      t.task_id, " +
                    "      t.task_nm, " +
                    "      t.st_dt, " +
                    "      t.end_dt, " +
                    "      t.no_of_days, " +
                    "      t.task_sts, " +
                    "      tsm.status_nm, " +
                    "      COALESCE(p.prj_cd, '') AS prj_cd, " +
                    "      pm.priority_nm, " +
                    "      ( " +
                    "        SELECT jsonb_agg(jsonb_build_object( " +
                    "          'empId', em.emp_id, " +
                    "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), " +
                    "          'photoUrl', em.photo_url, " +
                    "          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END " +
                    "        )) " +
                    "        FROM employee_master em " +
                    "        WHERE em.emp_id = t.emp_id " +
                    "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.task_id = t.task_id AND pc.is_live = true) " +
                    "      ) AS employees " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "    )) " +
                    " " +
                    "    UNION ALL " +
                    " " +
                    "    SELECT " +
                    "      t.emp_task_id AS task_id, " +
                    "      t.task_nm, " +
                    "      t.st_dt, " +
                    "      t.end_dt, " +
                    "      (t.end_dt - t.st_dt) AS no_of_days, " +
                    "      t.task_sts, " +
                    "      tsm.status_nm, " +
                    "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS prj_cd, " +
                    "      pm.priority_nm, " +
                    "      ( " +
                    "        SELECT jsonb_agg(jsonb_build_object( " +
                    "          'empId', em.emp_id, " +
                    "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), " +
                    "          'photoUrl', em.photo_url, " +
                    "          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END " +
                    "        )) " +
                    "        FROM employee_master em " +
                    "        WHERE em.emp_id = t.emp_id " +
                    "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.emp_task_id = t.emp_task_id AND pc.emp_task_id IS NOT NULL) " +
                    "      ) AS employees " +
                    "    FROM employee_individual_task_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( " +
                    "      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL " +
                    "    )) AND COALESCE(t.sts, true) = true " +
                    "  ) " +
                    "  SELECT jsonb_agg(sub) INTO v_upcoming " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'taskId', t.task_id, " +
                    "      'taskNm', t.task_nm, " +
                    "      'prjCd', t.prj_cd, " +
                    "      'stDt', t.st_dt, " +
                    "      'endDt', t.end_dt, " +
                    "      'durationDays', t.no_of_days, " +
                    "      'priority', CASE COALESCE(t.priority_nm, 'MEDIUM') " +
                    "                    WHEN 'LOW' THEN 'Low' " +
                    "                    WHEN 'NORMAL' THEN 'Medium' " +
                    "                    WHEN 'MEDIUM' THEN 'Medium' " +
                    "                    WHEN 'HIGH' THEN 'High' " +
                    "                    WHEN 'CRITICAL' THEN 'High' " +
                    "                    ELSE 'Medium' " +
                    "                  END, " +
                    "      'employees', COALESCE(t.employees, '[]'::jsonb) " +
                    "    ) AS sub " +
                    "    FROM all_upcoming t " +
                    "    WHERE t.status_nm <> 'COMPLETED' AND t.st_dt > v_today " +
                    "    ORDER BY t.end_dt ASC NULLS LAST " +
                    "    LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  /* 6. User Projects list with details and progress */ " +
                    "  SELECT jsonb_agg(sub) INTO v_my_projects " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'projectId',     p.prj_id, " +
                    "      'projectName',   p.prj_nm, " +
                    "      'projectCode',   p.prj_cd, " +
                    "      'clientName',    COALESCE(cm.coy_nm, (SELECT coy_nm FROM company_master LIMIT 1), ''), " +
                    "      'plantName',     COALESCE(pm.plt_nm, (SELECT plt_nm FROM plant_master LIMIT 1), ''), " +
                    "      'location',      COALESCE(cm.ct_vlg, (SELECT ct_vlg FROM company_master LIMIT 1), ''), " +
                    "      'logo',          p.logo, " +
                    "      'role',          COALESCE(pa.access_type, 'Team Member'), " +
                    "      'status',        CASE " +
                    "                         WHEN p.prj_sts = 'HOLD' THEN 'On Hold' " +
                    "                         WHEN p.prj_sts = 'CLOSED' THEN 'Completed' " +
                    "                         ELSE 'In Progress' " +
                    "                       END, " +
                    "      'dueDate',       p.end_dt, " +
                    "      'tasksAssigned', COUNT(t.task_id), " +
                    "      'openTasks',     COUNT(t.task_id) FILTER (WHERE tsm.status_nm <> 'COMPLETED'), " +
                    "      'progress',      ROUND( " +
                    "        CASE WHEN COUNT(t.task_id) > 0 " +
                    "          THEN (COUNT(t.task_id) FILTER (WHERE tsm.status_nm = 'COMPLETED')::NUMERIC / COUNT(t.task_id)) * 100 " +
                    "          ELSE 0 END, 0) " +
                    "    ) AS sub " +
                    "    FROM task_live_master t " +
                    "    JOIN milestone_live_master  ml ON ml.m_id   = t.m_id " +
                    "    JOIN project_live_master    p  ON p.prj_id  = ml.prj_id " +
                    "    LEFT JOIN company_master    cm ON cm.coy_id = p.coy_id " +
                    "    LEFT JOIN plant_master      pm ON pm.plt_id = p.plt_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN project_access pa ON pa.prj_id = p.prj_id AND pa.emp_id = p_emp_id AND pa.sts = true " +
                    "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "    )) AND p.prj_sts IN ('LIVE', 'CLOSED', 'HOLD') " +
                    "    GROUP BY p.prj_id, p.prj_nm, p.prj_cd, p.logo, cm.coy_nm, pm.plt_nm, cm.ct_vlg, p.prj_sts, pa.access_type, p.end_dt " +
                    "    ORDER BY p.prj_nm " +
                    "  ) x; " +
                    " " +
                    "  /* 8. Trend and Weekly Change Calculations */ " +
                    "  DECLARE " +
                    "    trend_rec RECORD; " +
                    "  BEGIN " +
                    "    WITH days AS ( " +
                    "      SELECT (v_today - i * INTERVAL '1 day')::DATE AS d " +
                    "      FROM generate_series(6, 0, -1) AS i " +
                    "    ), " +
                    "    trend_data AS ( " +
                    "      SELECT " +
                    "        d, " +
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d) AS assigned_count, " +
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d AND status_nm = 'OPEN' AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS open_count, " +
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d AND status_nm = 'WIP' AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS wip_count, " +
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE end_dt < d AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS overdue_count, " +
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE act_cmp_dt <= d) AS completed_count, " +
                    "        (SELECT COUNT(DISTINCT m.prj_id) " +
                    "         FROM task_live_master t_tr " +
                    "         JOIN milestone_live_master m ON m.m_id = t_tr.m_id " +
                    "         JOIN project_live_master p_tr ON p_tr.prj_id = m.prj_id " +
                    "         WHERE (t_tr.emp_id = p_emp_id OR t_tr.task_id IN ( " +
                    "           SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "         )) AND p_tr.prj_sts = 'LIVE' AND p_tr.st_dt <= d) AS projects_count " +
                    "      FROM days " +
                    "      ORDER BY d " +
                    "    ) " +
                    "    SELECT " +
                    "      jsonb_object_agg(metric, jsonb_build_object( " +
                    "        'trend', trend_array, " +
                    "        'weeklyChange', GREATEST(0, current_val - seven_days_ago_val) " +
                    "      )) " +
                    "    INTO v_metrics_trends " +
                    "    FROM ( " +
                    "      SELECT " +
                    "        'assignedTasks' AS metric, " +
                    "        (SELECT jsonb_agg(assigned_count) FROM trend_data) AS trend_array, " +
                    "        (SELECT assigned_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        COALESCE((SELECT assigned_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'openTasks' AS metric, " +
                    "        (SELECT jsonb_agg(open_count) FROM trend_data) AS trend_array, " +
                    "        (SELECT open_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        COALESCE((SELECT open_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'inProgress' AS metric, " +
                    "        (SELECT jsonb_agg(wip_count) FROM trend_data) AS trend_array, " +
                    "        (SELECT wip_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        COALESCE((SELECT wip_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'overdueTasks' AS metric, " +
                    "        (SELECT jsonb_agg(overdue_count) FROM trend_data) AS trend_array, " +
                    "        (SELECT overdue_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        COALESCE((SELECT overdue_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'completedTasks' AS metric, " +
                    "        (SELECT jsonb_agg(completed_count) FROM trend_data) AS trend_array, " +
                    "        (SELECT completed_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        COALESCE((SELECT completed_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'myProjects' AS metric, " +
                    "        (SELECT jsonb_agg(projects_count) FROM trend_data) AS trend_array, " +
                    "        (SELECT projects_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        COALESCE((SELECT projects_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val " +
                    "    ) x; " +
                    "  END; " +
                    " " +
                    "  /* 9. Recent Activity List */ " +
                    "  SELECT jsonb_agg(sub) INTO v_recent_activity " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'logId',      al.log_id, " +
                    "      'entityTyp',  al.entity_typ, " +
                    "      'entityId',   al.entity_id, " +
                    "      'statusFrom', al.status_from, " +
                    "      'statusTo',   al.status_to, " +
                    "      'logDt',      al.log_dt, " +
                    "      'message',    CASE " +
                    "                      WHEN al.entity_typ = 'TASK' THEN " +
                    "                        'Task \"' || COALESCE(t.task_nm, 'Unknown Task') || '\" updated from ' || al.status_from || ' to ' || al.status_to " +
                    "                      WHEN al.entity_typ = 'MILESTONE' THEN " +
                    "                        'Milestone \"' || COALESCE(m.mlstn_ttl, 'Unknown Milestone') || '\" updated from ' || al.status_from || ' to ' || al.status_to " +
                    "                      WHEN al.entity_typ = 'PROJECT' THEN " +
                    "                        'Project \"' || COALESCE(p.prj_nm, 'Unknown Project') || '\" updated from ' || al.status_from || ' to ' || al.status_to " +
                    "                      ELSE 'Activity log updated' " +
                    "                    END, " +
                    "      'projectName', COALESCE(p.prj_nm, p_ind.prj_nm, 'Internal') " +
                    "    ) AS sub " +
                    "    FROM activity_log_transaction al " +
                    "    LEFT JOIN task_live_master t ON al.entity_typ = 'TASK' AND t.task_id = al.entity_id " +
                    "    LEFT JOIN milestone_live_master m ON " +
                    "      (al.entity_typ = 'MILESTONE' AND m.m_id = al.entity_id) OR " +
                    "      (al.entity_typ = 'TASK' AND m.m_id = t.m_id) " +
                    "    LEFT JOIN project_live_master p ON " +
                    "      (al.entity_typ = 'PROJECT' AND p.prj_id = al.entity_id) OR " +
                    "      (m.prj_id = p.prj_id) " +
                    "    LEFT JOIN employee_individual_task_master ind ON al.entity_typ = 'TASK' AND ind.emp_task_id = al.entity_id " +
                    "    LEFT JOIN (SELECT DISTINCT prj_cd, prj_nm FROM project_live_master) p_ind ON p_ind.prj_cd = ind.task_asgn_to " +
                    "    WHERE " +
                    "      (al.entity_typ = 'TASK' AND (t.emp_id = p_emp_id OR ind.emp_id = p_emp_id OR t.task_id IN ( " +
                    "         SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "      ) OR ind.emp_task_id IN ( " +
                    "         SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL " +
                    "      ))) " +
                    "      OR (p.prj_id IN ( " +
                    "         SELECT DISTINCT ml_sub.prj_id " +
                    "         FROM task_live_master t_sub " +
                    "         JOIN milestone_live_master ml_sub ON ml_sub.m_id = t_sub.m_id " +
                    "         WHERE t_sub.emp_id = p_emp_id OR t_sub.task_id IN ( " +
                    "           SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "         ) " +
                    "      )) " +
                    "    ORDER BY al.log_dt DESC " +
                    "    LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  /* 10. Performance Calculations */ " +
                    "  SELECT COALESCE( " +
                    "    ROUND( " +
                    "      (COUNT(*) FILTER (WHERE status_nm = 'COMPLETED' AND (act_cmp_dt IS NULL OR act_cmp_dt <= end_dt))::NUMERIC / " +
                    "       NULLIF(COUNT(*) FILTER (WHERE status_nm = 'COMPLETED'), 0)) * 100, " +
                    "      0 " +
                    "    )::INT, " +
                    "    100 " +
                    "  ) INTO v_productivity " +
                    "  FROM temp_all_tasks; " +
                    " " +
                    "  v_quality := GREATEST(50, 100 - ((v_reassigned + v_rework) * 5)); " +
                    " " +
                    "  v_performance := jsonb_build_object( " +
                    "    'productivity', jsonb_build_object( " +
                    "      'score', v_productivity, " +
                    "      'rating', CASE " +
                    "                  WHEN v_productivity >= 90 THEN 'Excellent' " +
                    "                  WHEN v_productivity >= 75 THEN 'Good' " +
                    "                  WHEN v_productivity >= 50 THEN 'Satisfactory' " +
                    "                  ELSE 'Needs Improvement' " +
                    "                END " +
                    "    ), " +
                    "    'taskCompletion', jsonb_build_object( " +
                    "      'score', CASE WHEN v_total_tasks > 0 THEN ROUND((v_completed::NUMERIC/v_total_tasks)*100,0)::INT ELSE 100 END, " +
                    "      'rating', CASE " +
                    "                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 90 THEN 'Excellent' " +
                    "                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 75 THEN 'Good' " +
                    "                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 50 THEN 'Satisfactory' " +
                    "                  ELSE 'Needs Improvement' " +
                    "                END " +
                    "    ), " +
                    "    'qualityScore', jsonb_build_object( " +
                    "      'score', v_quality, " +
                    "      'rating', CASE " +
                    "                  WHEN v_quality >= 90 THEN 'Excellent' " +
                    "                  WHEN v_quality >= 75 THEN 'Good' " +
                    "                  WHEN v_quality >= 50 THEN 'Satisfactory' " +
                    "                  ELSE 'Needs Improvement' " +
                    "                END " +
                    "    ) " +
                    "  ); " +
                    " " +
                    "  /* 7. Combined response return */ " +
                    "  RETURN jsonb_build_object( " +
                    "    'profile', jsonb_build_object( " +
                    "      'empId', p_emp_id, 'fullName', v_full_name, " +
                    "      'role', COALESCE(v_emp.desig_nm, 'Site Engineer'), " +
                    "      'department', COALESCE(v_emp.dept_nm, 'Projects Department'), " +
                    "      'photoUrl', v_emp.photo_url), " +
                    "    'summary', jsonb_build_object( " +
                    "      'myTasksCount', (v_total_tasks - v_completed - v_overdue), " +
                    "      'completedTasksCount', v_completed, " +
                    "      'overdueTasksCount', v_overdue, " +
                    "      'dueTodayCount', v_due_today, " +
                    "      'myProjectsCount', v_my_prj_count, " +
                    "      'overallCompletion', CASE WHEN v_total_tasks > 0 " +
                    "        THEN ROUND((v_completed::NUMERIC/v_total_tasks)*100,2) ELSE 0 END), " +
                    "    'taskStatusCounts', jsonb_build_object( " +
                    "      'Completed', v_completed, 'In Progress', v_wip, " +
                    "      'Under Review', v_under_review, 'Overdue', v_overdue, " +
                    "      'Open', v_open, 'Reassigned', v_reassigned, " +
                    "      'Rework', v_rework, 'Draft', v_draft), " +
                    "    'todoList',      COALESCE(v_todo_list, '[]'::jsonb), " +
                    "    'upcomingTasks', COALESCE(v_upcoming, '[]'::jsonb), " +
                    "    'myProjects',    COALESCE(v_my_projects, '[]'::jsonb), " +
                    "    'metricsTrends', COALESCE(v_metrics_trends, '{}'::jsonb), " +
                    "    'recentActivity', COALESCE(v_recent_activity, '[]'::jsonb), " +
                    "    'performance',   v_performance " +
                    "  ); " +
                    "END; " +
                    "$$;"
                );
                System.out.println("get_user_dashboard stored procedure created/updated successfully.");
            } catch (Exception e) {
                System.err.println("Failed to create/update get_user_dashboard stored procedure: " + e.getMessage());
                if (e instanceof java.sql.SQLException) {
                    java.sql.SQLException sqle = (java.sql.SQLException) e;
                    System.err.println("SQL State: " + sqle.getSQLState());
                    System.err.println("Error Code: " + sqle.getErrorCode());
                }
                e.printStackTrace();
            }

            // 2e. Create/Update get_admin_dashboard SQL function
            try {
                System.out.println("Creating/Updating get_admin_dashboard stored procedure...");
                stmt.execute(
                    "CREATE OR REPLACE FUNCTION get_admin_dashboard() " +
                    "RETURNS jsonb " +
                    "LANGUAGE plpgsql " +
                    "SECURITY DEFINER " +
                    "AS $$ " +
                    "DECLARE " +
                    "  v_today         DATE := CURRENT_DATE; " +
                    "  v_emp_count     BIGINT; " +
                    "  v_dept_count    BIGINT; " +
                    "  v_coy_count     BIGINT; " +
                    "  v_plt_count     BIGINT; " +
                    "  v_total_prj     INT := 0; " +
                    "  v_on_track      INT := 0; " +
                    "  v_at_risk       INT := 0; " +
                    "  v_delayed_prj   INT := 0; " +
                    "  v_completed_prj INT := 0; " +
                    "  v_ms_total      INT := 0; " +
                    "  v_ms_completed  INT := 0; " +
                    "  v_ms_in_prog    INT := 0; " +
                    "  v_ms_overdue    INT := 0; " +
                    "  v_t_total       INT := 0; " +
                    "  v_t_completed   INT := 0; " +
                    "  v_t_in_prog     INT := 0; " +
                    "  v_t_todo        INT := 0; " +
                    "  v_t_overdue     INT := 0; " +
                    "  v_top_projects  jsonb; " +
                    "  v_deadlines     jsonb; " +
                    "  v_activities    jsonb; " +
                    "  rec RECORD; " +
                    "BEGIN " +
                    "  /* 1. Global Counts */ " +
                    "  SELECT COUNT(*) INTO v_emp_count  FROM employee_master; " +
                    "  SELECT COUNT(*) INTO v_dept_count FROM department_master; " +
                    "  SELECT COUNT(*) INTO v_coy_count  FROM company_master; " +
                    "  SELECT COUNT(*) INTO v_plt_count  FROM plant_master; " +
                    " " +
                    "  /* 2. Project Status Metrics */ " +
                    "  FOR rec IN SELECT prj_sts, end_dt FROM project_live_master LOOP " +
                    "    v_total_prj := v_total_prj + 1; " +
                    "    IF rec.prj_sts = 'CLOSED' THEN " +
                    "      v_completed_prj := v_completed_prj + 1; " +
                    "    ELSIF rec.end_dt IS NOT NULL AND rec.end_dt < v_today THEN " +
                    "      v_delayed_prj := v_delayed_prj + 1; " +
                    "    ELSIF rec.end_dt IS NOT NULL AND rec.end_dt < v_today + 7 THEN " +
                    "      v_at_risk := v_at_risk + 1; " +
                    "    ELSE " +
                    "      v_on_track := v_on_track + 1; " +
                    "    END IF; " +
                    "  END LOOP; " +
                    " " +
                    "  /* 3. Milestone Progress Metrics */ " +
                    "  FOR rec IN SELECT mlstn_sts, end_dt FROM milestone_live_master LOOP " +
                    "    v_ms_total := v_ms_total + 1; " +
                    "    IF rec.mlstn_sts IN ('COMPLETED','CLOSED') THEN " +
                    "      v_ms_completed := v_ms_completed + 1; " +
                    "    ELSE " +
                    "      v_ms_in_prog := v_ms_in_prog + 1; " +
                    "      IF rec.end_dt IS NOT NULL AND rec.end_dt < v_today THEN " +
                    "        v_ms_overdue := v_ms_overdue + 1; " +
                    "      END IF; " +
                    "    END IF; " +
                    "  END LOOP; " +
                    " " +
                    "  /* 4. Task Overview Metrics */ " +
                    "  FOR rec IN SELECT task_sts, end_dt FROM task_live_master LOOP " +
                    "    v_t_total := v_t_total + 1; " +
                    "    IF rec.task_sts = 5 THEN " +
                    "      v_t_completed := v_t_completed + 1; " +
                    "    ELSIF rec.task_sts IN (3, 4, 6, 7) THEN " +
                    "      v_t_in_prog := v_t_in_prog + 1; " +
                    "    ELSE " +
                    "      v_t_todo := v_t_todo + 1; " +
                    "    END IF; " +
                    " " +
                    "    IF rec.task_sts <> 5 AND (rec.task_sts = 8 OR (rec.end_dt IS NOT NULL AND rec.end_dt < v_today)) THEN " +
                    "      v_t_overdue := v_t_overdue + 1; " +
                    "    END IF; " +
                    "  END LOOP; " +
                    " " +
                    "  /* 5. Top Projects list by progress */ " +
                    "  SELECT jsonb_agg(sub ORDER BY (sub->>'progressPercent')::NUMERIC DESC) " +
                    "  INTO v_top_projects " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'projectId',      p.prj_id, " +
                    "      'projectName',    p.prj_nm, " +
                    "      'projectCode',    p.prj_cd, " +
                    "      'progressPercent', ROUND(CASE WHEN COUNT(t.task_id)>0 " +
                    "        THEN (COUNT(t.task_id) FILTER (WHERE t.task_sts=5)::NUMERIC/COUNT(t.task_id))*100 " +
                    "        ELSE 0 END, 2) " +
                    "    ) AS sub " +
                    "    FROM project_live_master p " +
                    "    LEFT JOIN milestone_live_master m ON m.prj_id = p.prj_id " +
                    "    LEFT JOIN task_live_master t ON t.m_id = m.m_id " +
                    "    GROUP BY p.prj_id, p.prj_nm, p.prj_cd " +
                    "    LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  /* 6. Upcoming Deadlines */ " +
                    "  SELECT jsonb_agg(sub ORDER BY sub->>'dueDate') INTO v_deadlines " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'title',      t.task_nm || COALESCE(' ('||t.task_cd||')',''), " +
                    "      'projectName',COALESCE(p.prj_nm,''), " +
                    "      'dueDate',    t.end_dt, " +
                    "      'timeLeft',   CASE WHEN t.end_dt < v_today THEN 'Overdue' " +
                    "                         ELSE (t.end_dt - v_today)::TEXT||' Days Left' END, " +
                    "      'isCritical', (t.end_dt - v_today) <= 2 " +
                    "    ) AS sub " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id  = t.m_id " +
                    "    LEFT JOIN project_live_master   p ON p.prj_id = m.prj_id " +
                    "    WHERE t.task_sts <> 5 AND t.end_dt IS NOT NULL " +
                    "    ORDER BY t.end_dt LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  /* 7. System Activities (Dynamic from activity_log_transaction) */ " +
                    "  SELECT jsonb_agg(sub) INTO v_activities " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'description', CASE " +
                    "        WHEN alt.entity_typ = 'TASK' THEN 'Task \"' || COALESCE(t.task_nm, 'Task') || '\" status changed from ' || COALESCE(alt.status_from, 'N/A') || ' to ' || COALESCE(alt.status_to, 'N/A') " +
                    "        WHEN alt.entity_typ = 'MILESTONE' THEN 'Milestone \"' || COALESCE(m.mlstn_ttl, 'Milestone') || '\" status changed from ' || COALESCE(alt.status_from, 'N/A') || ' to ' || COALESCE(alt.status_to, 'N/A') " +
                    "        WHEN alt.entity_typ = 'PROJECT' THEN 'Project \"' || COALESCE(p.prj_nm, 'Project') || '\" status changed from ' || COALESCE(alt.status_from, 'N/A') || ' to ' || COALESCE(alt.status_to, 'N/A') " +
                    "        ELSE 'Status changed' " +
                    "      END, " +
                    "      'actor', CASE " +
                    "        WHEN alt.entity_typ = 'TASK' THEN COALESCE( " +
                    "             NULLIF(TRIM(COALESCE(e.fst_nm,'')||' '||COALESCE(e.lst_nm,'')), ''), " +
                    "             ext.ext_emp_nm, " +
                    "             'System Admin' " +
                    "        ) " +
                    "        WHEN alt.entity_typ = 'MILESTONE' THEN 'Project Manager' " +
                    "        ELSE 'System Admin' " +
                    "      END, " +
                    "      'timestamp', CASE " +
                    "        WHEN alt.log_dt >= NOW() - INTERVAL '1 hour' THEN 'Just now' " +
                    "        WHEN alt.log_dt >= CURRENT_DATE THEN TO_CHAR(alt.log_dt, 'HH24:MI') " +
                    "        ELSE TO_CHAR(alt.log_dt, 'DD-Mon-YYYY') " +
                    "      END " +
                    "    ) AS sub " +
                    "    FROM activity_log_transaction alt " +
                    "    LEFT JOIN task_live_master t ON alt.entity_typ = 'TASK' AND alt.entity_id = t.task_id " +
                    "    LEFT JOIN employee_master e ON t.emp_id = e.emp_id " +
                    "    LEFT JOIN external_employee_master ext ON t.ext_emp_id = ext.ext_emp_id " +
                    "    LEFT JOIN milestone_live_master m ON alt.entity_typ = 'MILESTONE' AND alt.entity_id = m.m_id " +
                    "    LEFT JOIN project_live_master p ON alt.entity_typ = 'PROJECT' AND alt.entity_id = p.prj_id " +
                    "    ORDER BY alt.log_id DESC " +
                    "    LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  /* 8. Combined JSON Response */ " +
                    "  RETURN jsonb_build_object( " +
                    "    'employeeCount',       v_emp_count, " +
                    "    'departmentCount',     v_dept_count, " +
                    "    'companyCount',        v_coy_count, " +
                    "    'plantCount',          v_plt_count, " +
                    "    'activeProjectsCount', v_total_prj, " +
                    "    'criticalAlertsCount', v_t_overdue, " +
                    "    'projectStatus', jsonb_build_object( " +
                    "      'total',v_total_prj,'onTrack',v_on_track,'atRisk',v_at_risk, " +
                    "      'delayed',v_delayed_prj,'completed',v_completed_prj), " +
                    "    'milestoneProgress', jsonb_build_object( " +
                    "      'total',v_ms_total,'completed',v_ms_completed, " +
                    "      'progress',v_ms_in_prog,'overdue',v_ms_overdue, " +
                    "      'percentage', CASE WHEN v_ms_total > 0 THEN ROUND((v_ms_completed::NUMERIC/v_ms_total)*100, 2) ELSE 0 END, " +
                    "      'progressPercent', CASE WHEN v_ms_total > 0 THEN ROUND((v_ms_completed::NUMERIC/v_ms_total)*100, 2) ELSE 0 END), " +
                    "    'taskOverview', jsonb_build_object( " +
                    "      'total',v_t_total,'completed',v_t_completed, " +
                    "      'progress',v_t_in_prog,'todo',v_t_todo,'overdue',v_t_overdue), " +
                    "    'topProjects',       COALESCE(v_top_projects,'[]'::jsonb), " +
                    "    'upcomingDeadlines', COALESCE(v_deadlines,   '[]'::jsonb), " +
                    "    'systemActivities',  COALESCE(v_activities,  '[]'::jsonb) " +
                    "  ); " +
                    "END; " +
                    "$$;"
                );
                System.out.println("get_admin_dashboard stored procedure created/updated successfully.");
            } catch (Exception e) {
                System.err.println("Failed to create/update get_admin_dashboard stored procedure: " + e.getMessage());
                if (e instanceof java.sql.SQLException) {
                    java.sql.SQLException sqle = (java.sql.SQLException) e;
                    System.err.println("SQL State: " + sqle.getSQLState());
                    System.err.println("Error Code: " + sqle.getErrorCode());
                }
                e.printStackTrace();
            }

            // Create/Update get_pm_dashboard stored procedure
            try {
                System.out.println("Creating/Updating get_pm_dashboard stored procedure...");
                stmt.execute(
                    "CREATE OR REPLACE FUNCTION public.get_pm_dashboard() " +
                    " RETURNS jsonb " +
                    " LANGUAGE plpgsql " +
                    " SECURITY DEFINER " +
                    "AS $function$ " +
                    "DECLARE " +
                    "  v_today           DATE := CURRENT_DATE; " +
                    "  v_total_prj       INT  := 0; " +
                    "  v_live_prj        INT  := 0; " +
                    "  v_delayed_prj     INT  := 0; " +
                    "  v_progress_sum    NUMERIC := 0; " +
                    "  v_ms_completed    INT := 0; " +
                    "  v_ms_in_progress  INT := 0; " +
                    "  v_ms_not_started  INT := 0; " +
                    "  v_ms_delayed      INT := 0; " +
                    "  v_t_total         INT := 0; " +
                    "  v_t_completed     INT := 0; " +
                    "  v_t_in_progress   INT := 0; " +
                    "  v_t_under_review  INT := 0; " +
                    "  v_t_not_started   INT := 0; " +
                    "  v_t_overdue       INT := 0; " +
                    "  v_earliest_start  DATE; " +
                    "  v_latest_end      DATE; " +
                    "  v_planned_pct     NUMERIC := 0; " +
                    "  v_overall_pct     NUMERIC := 0; " +
                    "  v_delayed_ms      jsonb; " +
                    "  v_upcoming_ms     jsonb; " +
                    "  v_hp_tasks        jsonb; " +
                    "  rec               RECORD; " +
                    "  v_prj_t_total     INT; " +
                    "  v_prj_t_done      INT; " +
                    "  v_p_completed     INT := 0; " +
                    "  v_p_in_progress   INT := 0; " +
                    "  v_p_not_started   INT := 0; " +
                    "  v_p_delayed       INT := 0; " +
                    "  v_may_delay_prj   INT := 0; " +
                    "  v_prj_total_weight      NUMERIC; " +
                    "  v_prj_completed_weight  NUMERIC; " +
                    "  v_prj_progress          NUMERIC; " +
                    "  v_active_prj            INT := 0; " +
                    "BEGIN " +
                    "  SELECT MIN(st_dt), MAX(end_dt) INTO v_earliest_start, v_latest_end " +
                    "  FROM project_live_master; " +
                    " " +
                    "  FOR rec IN SELECT prj_id, prj_sts, end_dt FROM project_live_master LOOP " +
                    "    v_total_prj := v_total_prj + 1; " +
                    "    IF rec.prj_sts = 'LIVE' THEN v_live_prj := v_live_prj + 1; END IF; " +
                    " " +
                    "    IF rec.prj_sts IN ('LIVE', 'CLOSED') THEN " +
                    "      v_active_prj := v_active_prj + 1; " +
                    "      IF rec.prj_sts = 'CLOSED' THEN " +
                    "        v_prj_progress := 100.0; " +
                    "      ELSE " +
                    "        SELECT " +
                    "          COALESCE(SUM( " +
                    "            CASE " +
                    "              WHEN t.wrk_days IS NOT NULL AND t.wrk_days > 0 THEN t.wrk_days " +
                    "              WHEN t.no_of_days IS NOT NULL AND t.no_of_days > 0 THEN t.no_of_days " +
                    "              ELSE 1.0 " +
                    "            END " +
                    "          ), 0), " +
                    "          COALESCE(SUM( " +
                    "            CASE " +
                    "              WHEN tsm.status_nm = 'COMPLETED' THEN 100.0 " +
                    "              WHEN tsm.status_nm = 'UNDER_REVIEW' THEN 80.0 " +
                    "              WHEN tsm.status_nm = 'WIP' THEN 50.0 " +
                    "              WHEN tsm.status_nm = 'REWORK' THEN 20.0 " +
                    "              ELSE 0.0 " +
                    "            END / 100.0 * " +
                    "            CASE " +
                    "              WHEN t.wrk_days IS NOT NULL AND t.wrk_days > 0 THEN t.wrk_days " +
                    "              WHEN t.no_of_days IS NOT NULL AND t.no_of_days > 0 THEN t.no_of_days " +
                    "              ELSE 1.0 " +
                    "            END " +
                    "          ), 0) " +
                    "        INTO v_prj_total_weight, v_prj_completed_weight " +
                    "        FROM milestone_live_master m " +
                    "        JOIN task_live_master t ON t.m_id = m.m_id " +
                    "        LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "        WHERE m.prj_id = rec.prj_id; " +
                    " " +
                    "        IF v_prj_total_weight > 0 THEN " +
                    "          v_prj_progress := (v_prj_completed_weight / v_prj_total_weight) * 100.0; " +
                    "        ELSE " +
                    "          v_prj_progress := 0.0; " +
                    "        END IF; " +
                    "      END IF; " +
                    "      v_progress_sum := v_progress_sum + v_prj_progress; " +
                    "    ELSE " +
                    "      v_prj_progress := 0.0; " +
                    "    END IF; " +
                    " " +
                    "    IF rec.prj_sts = 'CLOSED' THEN " +
                    "      v_p_completed := v_p_completed + 1; " +
                    "    ELSIF rec.prj_sts = 'LIVE' AND rec.end_dt IS NOT NULL AND rec.end_dt < v_today AND v_prj_progress < 100 THEN " +
                    "      v_p_delayed := v_p_delayed + 1; " +
                    "      v_delayed_prj := v_delayed_prj + 1; " +
                    "    ELSIF rec.prj_sts = 'LIVE' THEN " +
                    "      v_p_in_progress := v_p_in_progress + 1; " +
                    "    ELSE " +
                    "      v_p_not_started := v_p_not_started + 1; " +
                    "    END IF; " +
                    " " +
                    "    IF rec.prj_sts = 'LIVE' AND rec.end_dt >= v_today AND rec.end_dt < v_today + 7 THEN " +
                    "      v_may_delay_prj := v_may_delay_prj + 1; " +
                    "    END IF; " +
                    "  END LOOP; " +
                    " " +
                    "  v_overall_pct := CASE WHEN v_active_prj > 0 THEN v_progress_sum / v_active_prj ELSE 0 END; " +
                    " " +
                    "  IF v_earliest_start IS NOT NULL AND v_latest_end IS NOT NULL AND v_latest_end > v_earliest_start THEN " +
                    "    v_planned_pct := LEAST(100, GREATEST(0, " +
                    "      ((v_today - v_earliest_start)::NUMERIC / (v_latest_end - v_earliest_start)) * 100)); " +
                    "  END IF; " +
                    " " +
                    "  FOR rec IN SELECT mlstn_sts, st_dt, end_dt FROM milestone_live_master LOOP " +
                    "    IF rec.mlstn_sts IN ('COMPLETED','CLOSED') THEN " +
                    "      v_ms_completed := v_ms_completed + 1; " +
                    "    ELSIF rec.end_dt IS NOT NULL AND rec.end_dt < v_today THEN " +
                    "      v_ms_delayed := v_ms_delayed + 1; " +
                    "    ELSIF rec.st_dt IS NOT NULL AND rec.st_dt < v_today THEN " +
                    "      v_ms_in_progress := v_ms_in_progress + 1; " +
                    "    ELSE " +
                    "      v_ms_not_started := v_ms_not_started + 1; " +
                    "    END IF; " +
                    "  END LOOP; " +
                    " " +
                    "  FOR rec IN SELECT task_sts, end_dt FROM task_live_master LOOP " +
                    "    v_t_total := v_t_total + 1; " +
                    "    IF rec.task_sts = 5 THEN " +
                    "      v_t_completed := v_t_completed + 1; " +
                    "    ELSIF rec.task_sts = 8 OR (rec.end_dt IS NOT NULL AND rec.end_dt < v_today) THEN " +
                    "      v_t_overdue := v_t_overdue + 1; " +
                    "    ELSIF rec.task_sts = 4 THEN " +
                    "      v_t_under_review := v_t_under_review + 1; " +
                    "    ELSIF rec.task_sts IN (3, 6, 7) THEN " +
                    "      v_t_in_progress := v_t_in_progress + 1; " +
                    "    ELSE " +
                    "      v_t_not_started := v_t_not_started + 1; " +
                    "    END IF; " +
                    "  END LOOP; " +
                    " " +
                    "  SELECT COALESCE(jsonb_agg(sub), '[]'::jsonb) INTO v_delayed_ms " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'milestoneTitle',m.mlstn_ttl,'projectCd',p.prj_cd, " +
                    "      'delayDays',(v_today - m.end_dt)) AS sub " +
                    "    FROM milestone_live_master m JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    WHERE m.mlstn_sts NOT IN ('COMPLETED','CLOSED') " +
                    "      AND m.end_dt IS NOT NULL AND m.end_dt < v_today " +
                    "    ORDER BY m.end_dt ASC LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  SELECT COALESCE(jsonb_agg(sub), '[]'::jsonb) INTO v_upcoming_ms " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'milestoneTitle',m.mlstn_ttl,'projectCd',p.prj_cd, " +
                    "      'dueDate',TO_CHAR(m.st_dt,'DD-Mon-YYYY'),'status',COALESCE(m.mlstn_sts,'Pending')) AS sub " +
                    "    FROM milestone_live_master m JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    WHERE m.mlstn_sts NOT IN ('COMPLETED','CLOSED') " +
                    "      AND m.st_dt >= v_today AND m.st_dt < v_today + 30 " +
                    "    ORDER BY m.st_dt ASC LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  SELECT COALESCE(jsonb_agg(sub), '[]'::jsonb) INTO v_hp_tasks " +
                    "  FROM ( " +
                    "    SELECT jsonb_build_object( " +
                    "      'taskNm',t.task_nm,'projectCd',COALESCE(p.prj_cd,''), " +
                    "      'assigneeNm', COALESCE( " +
                    "         NULLIF(TRIM(COALESCE(e.fst_nm,'')||' '||COALESCE(e.lst_nm,'')), ''), " +
                    "         ext.ext_emp_nm, " +
                    "         '' " +
                    "      ), " +
                    "      'dueDate',TO_CHAR(t.end_dt,'DD-Mon-YYYY')) AS sub " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    LEFT JOIN employee_master e ON e.emp_id = t.emp_id " +
                    "    LEFT JOIN external_employee_master ext ON ext.ext_emp_id = t.ext_emp_id " +
                    "    WHERE t.task_sts <> 5 AND t.end_dt >= v_today " +
                    "    ORDER BY t.priority DESC, t.end_dt ASC LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  RETURN jsonb_build_object( " +
                    "    'summary', jsonb_build_object( " +
                    "      'totalProjects',v_total_prj,'liveProjects',v_live_prj, " +
                    "      'liveProjectsPercentage',CASE WHEN v_total_prj>0 THEN ROUND((v_live_prj::NUMERIC/v_total_prj)*100,2) ELSE 0 END, " +
                    "      'overallProgress',ROUND(v_overall_pct,2), " +
                    "      'delayedProjects',v_delayed_prj, " +
                    "      'delayedProjectsPercentage',CASE WHEN v_total_prj>0 THEN ROUND((v_delayed_prj::NUMERIC/v_total_prj)*100,2) ELSE 0 END, " +
                    "      'overdueTasksCount',v_t_overdue, " +
                    "      'overdueTasksPercentage',CASE WHEN v_t_total>0 THEN ROUND((v_t_overdue::NUMERIC/v_t_total)*100,2) ELSE 0 END, " +
                    "      'upcomingMilestonesCount',jsonb_array_length(v_upcoming_ms)), " +
                    "    'portfolioProgress', jsonb_build_object( " +
                    "      'completed',v_p_completed,'inProgress',v_p_in_progress, " +
                    "      'notStarted',v_p_not_started,'delayed',v_p_delayed, " +
                    "      'total',v_p_completed+v_p_in_progress+v_p_not_started+v_p_delayed), " +
                    "    'milestoneStatus', jsonb_build_object( " +
                    "      'completed',v_ms_completed,'inProgress',v_ms_in_progress, " +
                    "      'notStarted',v_ms_not_started,'delayed',v_ms_delayed, " +
                    "      'total',v_ms_completed+v_ms_in_progress+v_ms_not_started+v_ms_delayed), " +
                    "    'taskStatus', jsonb_build_object( " +
                    "      'completed',v_t_completed,'inProgress',v_t_in_progress, " +
                    "      'underReview',v_t_under_review,'notStarted',v_t_not_started, " +
                    "      'overdue',v_t_overdue, " +
                    "      'total',v_t_total), " +
                    "    'forecastSummary', jsonb_build_object( " +
                    "      'currentProgress',ROUND(v_overall_pct,2), " +
                    "      'plannedProgress',ROUND(v_planned_pct,2), " +
                    "      'variance',ROUND(v_overall_pct-v_planned_pct,2), " +
                    "      'expectedCompletionDate',TO_CHAR(v_latest_end,'DD-Mon-YYYY'), " +
                    "      'daysAhead',CASE WHEN v_latest_end IS NOT NULL THEN (v_latest_end-v_today) ELSE 0 END, " +
                    "      'projectsAtRiskCount',v_delayed_prj, " +
                    "      'projectsAtRiskPercentage',CASE WHEN v_total_prj>0 THEN ROUND((v_delayed_prj::NUMERIC/v_total_prj)*100,2) ELSE 0 END, " +
                    "      'onTrackProjectsCount',v_total_prj-v_delayed_prj, " +
                    "      'onTrackProjectsPercentage',CASE WHEN v_total_prj>0 THEN ROUND(((v_total_prj-v_delayed_prj)::NUMERIC/v_total_prj)*100,2) ELSE 0 END, " +
                    "      'mayDelayProjectsCount',v_may_delay_prj, " +
                    "      'mayDelayProjectsPercentage',CASE WHEN v_total_prj>0 THEN ROUND((v_may_delay_prj::NUMERIC/v_total_prj)*100,2) ELSE 0 END, " +
                    "      'atRiskProjectsCount',v_delayed_prj, " +
                    "      'atRiskProjectsPercentage',CASE WHEN v_total_prj>0 THEN ROUND((v_delayed_prj::NUMERIC/v_total_prj)*100,2) ELSE 0 END), " +
                    "    'delayedMilestones', v_delayed_ms, " +
                    "    'upcomingMilestones',v_upcoming_ms, " +
                    "    'highPriorityTasks', v_hp_tasks " +
                    "  ); " +
                    "END; " +
                    "$function$ "
                );
                System.out.println("get_pm_dashboard stored procedure created/updated successfully.");
            } catch (Exception e) {
                System.err.println("Failed to create/update get_pm_dashboard stored procedure: " + e.getMessage());
                if (e instanceof java.sql.SQLException) {
                    java.sql.SQLException sqle = (java.sql.SQLException) e;
                    System.err.println("SQL State: " + sqle.getSQLState());
                    System.err.println("Error Code: " + sqle.getErrorCode());
                }
                e.printStackTrace();
            }

            // Drop check constraints on activity_log_transaction to allow generic logging
            try {
                System.out.println("Dropping check constraints on activity_log_transaction if they exist...");
                stmt.execute("ALTER TABLE activity_log_transaction DROP CONSTRAINT IF EXISTS activity_log_transaction_entity_typ_check");
                stmt.execute("ALTER TABLE activity_log_transaction DROP CONSTRAINT IF EXISTS check_entity_typ");
                stmt.execute("ALTER TABLE activity_log_transaction DROP CONSTRAINT IF EXISTS activity_log_transaction_entity_typ_check1");
            } catch (Exception e) {
                System.err.println("Could not drop check constraints on activity_log_transaction: " + e.getMessage());
            }
        } catch (Exception e) {
            System.err.println("DatabaseMigrator migration failed: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void dropForeignKeysReferencingTaskStatus(Connection conn) throws Exception {
        String sql = "SELECT tc.table_name, co.conname as constraint_name " +
                     "FROM information_schema.table_constraints AS tc " +
                     "JOIN information_schema.key_column_usage AS kcu " +
                     "  ON tc.constraint_name = kcu.constraint_name " +
                     "  AND tc.table_schema = kcu.table_schema " +
                     "JOIN information_schema.constraint_column_usage AS ccu " +
                     "  ON ccu.constraint_name = tc.constraint_name " +
                     "  AND ccu.table_schema = tc.table_schema " +
                     "JOIN pg_constraint co ON co.conname = tc.constraint_name " +
                     "WHERE tc.constraint_type = 'FOREIGN KEY' " +
                     "  AND ccu.table_name = 'task_status_master'";
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            List<String> dropCommands = new ArrayList<>();
            while (rs.next()) {
                String tableName = rs.getString("table_name");
                String constraintName = rs.getString("constraint_name");
                dropCommands.add("ALTER TABLE " + tableName + " DROP CONSTRAINT " + constraintName);
            }
            for (String cmd : dropCommands) {
                System.out.println("Executing: " + cmd);
                try {
                    stmt.execute(cmd);
                } catch (Exception ex) {
                    System.err.println("Failed to drop constraint: " + ex.getMessage());
                }
            }
        }
    }

    @Component
    public static class JpaDependencySetup implements BeanFactoryPostProcessor {
        @Override
        public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException {
            if (beanFactory.containsBeanDefinition("entityManagerFactory")) {
                BeanDefinition bd = beanFactory.getBeanDefinition("entityManagerFactory");
                String[] dependsOn = bd.getDependsOn();
                if (dependsOn == null) {
                    bd.setDependsOn("databaseMigrator");
                } else {
                    List<String> list = new ArrayList<>(Arrays.asList(dependsOn));
                    if (!list.contains("databaseMigrator")) {
                        list.add("databaseMigrator");
                        bd.setDependsOn(list.toArray(new String[0]));
                    }
                }
            }
        }
    }
}
