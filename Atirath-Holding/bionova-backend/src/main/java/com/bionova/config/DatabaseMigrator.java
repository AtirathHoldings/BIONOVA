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
            try {
                stmt.execute("SET lock_timeout = 10000");
            } catch (Exception e) {}


            // 1. Create and populate task_status_master
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS task_status_master (" +
                "    status_id INTEGER PRIMARY KEY," +
                "    status_nm VARCHAR(20) NOT NULL" +
                ")"
            );

            // Drop unique constraint on status_nm if it exists
            try {
                stmt.execute("ALTER TABLE task_status_master DROP CONSTRAINT IF EXISTS task_status_master_status_nm_key");
                stmt.execute("ALTER TABLE task_status_master DROP CONSTRAINT IF EXISTS uklxpnguw8spv01m95oi9clwtja");
                stmt.execute("DROP INDEX IF EXISTS task_status_master_status_nm_key");
                stmt.execute("DROP INDEX IF EXISTS uklxpnguw8spv01m95oi9clwtja");
            } catch (Exception ex) {
                System.err.println("Could not drop unique constraint on status_nm: " + ex.getMessage());
            }

            // Add sub_status_nm column to task_status_master if not exists
            try {
                stmt.execute("ALTER TABLE task_status_master ADD COLUMN IF NOT EXISTS sub_status_nm VARCHAR(255)");
            } catch (Exception ex) {
                System.err.println("Could not add sub_status_nm column to task_status_master: " + ex.getMessage());
            }

            // Ensure sub_status column exists in task tables
            String[] targetTables = {"task_live_master", "task_draft_master", "employee_individual_task_master"};
            for (String tbl : targetTables) {
                try {
                    stmt.execute("ALTER TABLE " + tbl + " ADD COLUMN IF NOT EXISTS sub_status VARCHAR(50)");
                } catch (Exception ex) {
                    System.err.println("Could not add sub_status column to " + tbl + ": " + ex.getMessage());
                }
            }

            // Migrate task_sts and sub_status to the 5-status schema
            for (String tbl : targetTables) {
                try {
                    stmt.execute("UPDATE " + tbl + " SET sub_status = 'Under Review', task_sts = 3 WHERE task_sts = 4");
                    stmt.execute("UPDATE " + tbl + " SET sub_status = 'Reassign', task_sts = 3 WHERE task_sts = 6");
                    stmt.execute("UPDATE " + tbl + " SET sub_status = 'Rework', task_sts = 3 WHERE task_sts = 7");
                    stmt.execute("UPDATE " + tbl + " SET sub_status = 'Overdue', task_sts = 2 WHERE task_sts = 8");
                    stmt.execute("UPDATE " + tbl + " SET sub_status = 'Overdue', task_sts = 3 WHERE task_sts = 13");
                    stmt.execute("UPDATE " + tbl + " SET sub_status = 'Lead', task_sts = 4 WHERE task_sts = 10");
                    stmt.execute("UPDATE " + tbl + " SET sub_status = 'On Time', task_sts = 4 WHERE task_sts = 11");
                    stmt.execute("UPDATE " + tbl + " SET sub_status = 'Lag', task_sts = 4 WHERE task_sts = 12");
                    
                    // After the above mappings, we map completed (5) to status 4:
                    stmt.execute("UPDATE " + tbl + " SET task_sts = 4 WHERE task_sts = 5");
                    // And hold (9) to status 5:
                    stmt.execute("UPDATE " + tbl + " SET task_sts = 5 WHERE task_sts = 9");
                } catch (Exception ex) {
                    System.err.println("Failed to migrate status in table " + tbl + ": " + ex.getMessage());
                }
            }

            // Populate the new status master rows (exactly 5 statuses)
            stmt.execute("INSERT INTO task_status_master (status_id, status_nm, sub_status_nm) VALUES " +
                "(1, 'Draft', NULL), " +
                "(2, 'Open', 'Overdue'), " +
                "(3, 'WIP', 'Under Review, Reassign, Rework, Overdue'), " +
                "(4, 'Closed', 'Lead, On Time, Lag'), " +
                "(5, 'Hold', NULL) " +
                "ON CONFLICT (status_id) DO UPDATE SET status_nm = EXCLUDED.status_nm, sub_status_nm = EXCLUDED.sub_status_nm");

            try {
                stmt.execute("DELETE FROM task_status_master WHERE status_id > 5");
            } catch (Exception ex) {}

            System.out.println("task_status_master initialized with 5 statuses.");

            // Update some tasks for emp_id = 5 to cover various scenarios
            try {
                System.out.println("Updating select tasks of emp_id = 5 for scenario demonstration...");
                
                // Get task_ids for emp_id = 5
                List<Long> taskIds = new ArrayList<>();
                try (ResultSet rs = stmt.executeQuery("SELECT task_id FROM task_live_master WHERE emp_id = 5 ORDER BY task_id")) {
                    while (rs.next()) {
                        taskIds.add(rs.getLong("task_id"));
                    }
                }
                
                // Set various scenarios on task_live_master
                if (taskIds.size() > 0) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 1, sub_status = NULL WHERE task_id = " + taskIds.get(0)); // Draft
                }
                if (taskIds.size() > 1) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 2, sub_status = NULL WHERE task_id = " + taskIds.get(1)); // Open
                }
                if (taskIds.size() > 2) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 2, sub_status = 'Overdue' WHERE task_id = " + taskIds.get(2)); // Open (Overdue)
                }
                if (taskIds.size() > 3) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 3, sub_status = 'Under Review' WHERE task_id = " + taskIds.get(3)); // WIP (Under Review)
                }
                if (taskIds.size() > 4) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 3, sub_status = 'Reassign' WHERE task_id = " + taskIds.get(4)); // WIP (Reassign)
                }
                if (taskIds.size() > 5) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 3, sub_status = 'Rework' WHERE task_id = " + taskIds.get(5)); // WIP (Rework)
                }
                if (taskIds.size() > 6) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 3, sub_status = 'Overdue' WHERE task_id = " + taskIds.get(6)); // WIP (Overdue)
                }
                if (taskIds.size() > 7) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 3, sub_status = NULL WHERE task_id = " + taskIds.get(7)); // WIP
                }
                if (taskIds.size() > 8) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 4, sub_status = 'Lead' WHERE task_id = " + taskIds.get(8)); // Completed (Lead)
                }
                if (taskIds.size() > 9) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 4, sub_status = 'On Time' WHERE task_id = " + taskIds.get(9)); // Completed (On Time)
                }
                if (taskIds.size() > 10) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 4, sub_status = 'Lag' WHERE task_id = " + taskIds.get(10)); // Completed (Lag)
                }
                if (taskIds.size() > 11) {
                    stmt.execute("UPDATE task_live_master SET task_sts = 5, sub_status = NULL WHERE task_id = " + taskIds.get(11)); // Hold
                }
                
                // Get individual task_ids for emp_id = 5
                List<Long> individualTaskIds = new ArrayList<>();
                try (ResultSet rs = stmt.executeQuery("SELECT emp_task_id FROM employee_individual_task_master WHERE emp_id = 5 ORDER BY emp_task_id")) {
                    while (rs.next()) {
                        individualTaskIds.add(rs.getLong("emp_task_id"));
                    }
                }
                
                // Set some scenarios on employee_individual_task_master
                if (individualTaskIds.size() > 0) {
                    stmt.execute("UPDATE employee_individual_task_master SET task_sts = 3, sub_status = 'Rework' WHERE emp_task_id = " + individualTaskIds.get(0));
                }
                if (individualTaskIds.size() > 1) {
                    stmt.execute("UPDATE employee_individual_task_master SET task_sts = 4, sub_status = 'On Time' WHERE emp_task_id = " + individualTaskIds.get(1));
                }
                
                System.out.println("Demo tasks updated successfully for emp_id = 5.");
            } catch (Exception ex) {
                System.err.println("Could not update demo tasks for emp_id = 5: " + ex.getMessage());
            }

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
                    "  v_reassigned_raw INT := 0; " +
                    "  v_rework_raw     INT := 0; " +
                    "  v_main_completed INT := 0; " +
                    "  v_main_wip       INT := 0; " +
                    "  v_main_open      INT := 0; " +
                    "  v_my_prj_count   BIGINT := 0; " +
                    "  v_todo_list      jsonb; " +
                    "  v_upcoming       jsonb; " +
                    "  v_my_projects    jsonb; " +
                    "  v_metrics_trends jsonb; " +
                    "  v_recent_activity jsonb; " +
                    "  v_performance    jsonb; " +
                    "  v_productivity   INT := 100; " +
                    "  v_quality        INT := 100; " +
                    "  v_on_time_delivery INT := 100; " +
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
                    "      t.sub_status, " +
                    "      COALESCE(p.prj_cd || ' - ' || m.mlstn_ttl, '') AS project_info, " +
                    "      COALESCE(p.prj_cd, '') AS prj_cd, " +
                    "      CASE " +
                    "        WHEN t.emp_id = p_emp_id THEN 'Executor' " +
                    "        WHEN t.task_id IN (SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL) THEN 'Contributor' " +
                    "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 1) THEN 'Reviewer' " +
                    "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 2) THEN 'Approver' " +
                    "        ELSE 'Executor' " +
                    "      END AS user_badge, " +
                    "      'PROJECT' AS task_source, " +
                    "      pm.priority_nm " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "    ) OR t.task_id IN ( " +
                    "      SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
                    "    )) " +
                    " " +
                    "    UNION ALL " +
                    " " +
                    "    SELECT " +
                    "      t.emp_task_id AS task_id, " +
                    "      t.task_nm, " +
                    "      t.st_dt, " +
                    "      t.end_dt, " +
                    "      CASE WHEN tsm.status_nm = 'Closed' THEN t.end_dt ELSE NULL END AS act_cmp_dt, " +
                    "      (t.end_dt - t.st_dt) AS no_of_days, " +
                    "      t.task_sts, " +
                    "      tsm.status_nm, " +
                    "      t.sub_status, " +
                    "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS project_info, " +
                    "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS prj_cd, " +
                    "      CASE " +
                    "        WHEN t.emp_id = p_emp_id THEN 'Executor' " +
                    "        WHEN t.emp_task_id IN (SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL) THEN 'Contributor' " +
                    "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 1) THEN 'Reviewer' " +
                    "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 2) THEN 'Approver' " +
                    "        ELSE 'Executor' " +
                    "      END AS user_badge, " +
                    "      'INDIVIDUAL' AS task_source, " +
                    "      pm.priority_nm " +
                    "    FROM employee_individual_task_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( " +
                    "      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL " +
                    "    ) OR t.emp_task_id IN ( " +
                    "      SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL " +
                    "    )) AND COALESCE(t.sts, true) = true " +
                    "  ; " +
                    "  SELECT " +
                    "    COUNT(*) FILTER (WHERE st_dt IS NULL OR st_dt <= v_today OR COALESCE(LOWER(status_nm), '') = 'closed'), " +
                    "    COUNT(*) FILTER (WHERE COALESCE(LOWER(status_nm), '') = 'closed'), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') <> 'closed' AND (COALESCE(LOWER(sub_status), '') = 'overdue' OR (end_dt IS NOT NULL AND end_dt < v_today))), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') <> 'closed' AND end_dt = v_today), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') = 'wip' AND NOT (COALESCE(LOWER(sub_status), '') = 'overdue' OR (COALESCE(LOWER(status_nm), '') <> 'closed' AND end_dt IS NOT NULL AND end_dt < v_today))), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') = 'wip' AND COALESCE(LOWER(sub_status), '') = 'under review' AND NOT (COALESCE(LOWER(sub_status), '') = 'overdue' OR (COALESCE(LOWER(status_nm), '') <> 'closed' AND end_dt IS NOT NULL AND end_dt < v_today))), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') IN ('open', 'hold') AND NOT (COALESCE(LOWER(sub_status), '') = 'overdue' OR (COALESCE(LOWER(status_nm), '') <> 'closed' AND end_dt IS NOT NULL AND end_dt < v_today))), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') = 'wip' AND COALESCE(LOWER(sub_status), '') = 'reassign' AND NOT (COALESCE(LOWER(sub_status), '') = 'overdue' OR (COALESCE(LOWER(status_nm), '') <> 'closed' AND end_dt IS NOT NULL AND end_dt < v_today))), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') = 'wip' AND COALESCE(LOWER(sub_status), '') = 'rework' AND NOT (COALESCE(LOWER(sub_status), '') = 'overdue' OR (COALESCE(LOWER(status_nm), '') <> 'closed' AND end_dt IS NOT NULL AND end_dt < v_today))), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') = 'draft' AND NOT (COALESCE(LOWER(sub_status), '') = 'overdue' OR (COALESCE(LOWER(status_nm), '') <> 'closed' AND end_dt IS NOT NULL AND end_dt < v_today))), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') = 'wip' AND COALESCE(LOWER(sub_status), '') = 'reassign'), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') = 'wip' AND COALESCE(LOWER(sub_status), '') = 'rework'), " +
                    "    COUNT(*) FILTER (WHERE COALESCE(LOWER(status_nm), '') = 'closed'), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') = 'wip'), " +
                    "    COUNT(*) FILTER (WHERE (st_dt IS NULL OR st_dt <= v_today) AND COALESCE(LOWER(status_nm), '') IN ('open', 'hold')) " +
                    "  INTO v_total_tasks, v_completed, v_overdue, v_due_today, " +
                    "       v_wip, v_under_review, v_open, v_reassigned, v_rework, v_draft, " +
                    "       v_reassigned_raw, v_rework_raw, " +
                    "       v_main_completed, v_main_wip, v_main_open " +
                    "  FROM temp_all_tasks; " +
                    " " +
                    "  SELECT COUNT(DISTINCT m.prj_id) INTO v_my_prj_count " +
                    "  FROM task_live_master t " +
                    "  JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "  JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "  WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "    SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "  ) OR t.task_id IN ( " +
                    "    SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
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
                    "      t.sub_status, " +
                    "      COALESCE(p.prj_cd || ' - ' || m.mlstn_ttl, '') AS project_info, " +
                    "      CASE " +
                    "        WHEN t.emp_id = p_emp_id THEN 'Executor' " +
                    "        WHEN t.task_id IN (SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL) THEN 'Contributor' " +
                    "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 1) THEN 'Reviewer' " +
                    "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 2) THEN 'Approver' " +
                    "        ELSE 'Executor' " +
                    "      END AS user_badge, " +
                    "      'PROJECT' AS task_source, " +
                    "      pm.priority_nm, " +
                    "      ( " +
                    "        SELECT jsonb_agg(jsonb_build_object( " +
                    "          'empId', em.emp_id, " +
                    "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), " +
                    "          'photoUrl', em.photo_url, " +
                    "          'role', CASE " +
                    "                    WHEN t.emp_id = em.emp_id THEN 'Executor' " +
                    "                    WHEN em.emp_id IN (SELECT tm.emp_id FROM team_members tm WHERE tm.task_id = t.task_id) THEN 'Contributor' " +
                    "                    ELSE 'Reviewer/Approver' " +
                    "                  END " +
                    "        )) " +
                    "        FROM employee_master em " +
                    "        WHERE em.emp_id = t.emp_id " +
                    "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.task_id = t.task_id AND pc.is_live = true) " +
                    "           OR em.emp_id IN (SELECT tm.emp_id FROM team_members tm WHERE tm.task_id = t.task_id) " +
                    "      ) AS employees " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "    ) OR t.task_id IN ( " +
                    "      SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
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
                    "      t.sub_status, " +
                    "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS project_info, " +
                    "      CASE " +
                    "        WHEN t.emp_id = p_emp_id THEN 'Executor' " +
                    "        WHEN t.emp_task_id IN (SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL) THEN 'Contributor' " +
                    "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 1) THEN 'Reviewer' " +
                    "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 2) THEN 'Approver' " +
                    "        ELSE 'Executor' " +
                    "      END AS user_badge, " +
                    "      'INDIVIDUAL' AS task_source, " +
                    "      pm.priority_nm, " +
                    "      ( " +
                    "        SELECT jsonb_agg(jsonb_build_object( " +
                    "          'empId', em.emp_id, " +
                    "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), " +
                    "          'photoUrl', em.photo_url, " +
                    "          'role', CASE " +
                    "                    WHEN t.emp_id = em.emp_id THEN 'Executor' " +
                    "                    WHEN em.emp_id IN (SELECT tm.emp_id FROM team_members tm WHERE tm.emp_task_id = t.emp_task_id) THEN 'Contributor' " +
                    "                    ELSE 'Reviewer/Approver' " +
                    "                  END " +
                    "        )) " +
                    "        FROM employee_master em " +
                    "        WHERE em.emp_id = t.emp_id " +
                    "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.emp_task_id = t.emp_task_id AND pc.emp_task_id IS NOT NULL) " +
                    "           OR em.emp_id IN (SELECT tm.emp_id FROM team_members tm WHERE tm.emp_task_id = t.emp_task_id) " +
                    "      ) AS employees " +
                    "    FROM employee_individual_task_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( " +
                    "      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL " +
                    "    ) OR t.emp_task_id IN ( " +
                    "      SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL " +
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
                    "      'isOverdue', (COALESCE(LOWER(t.sub_status), '') = 'overdue' OR (COALESCE(LOWER(t.status_nm), '') <> 'closed' AND t.end_dt < v_today)), " +
                    "      'isDueToday', (COALESCE(LOWER(t.status_nm), '') <> 'closed' AND t.end_dt = v_today), " +
                    "      'priority', CASE COALESCE(t.priority_nm, 'MEDIUM') " +
                    "                    WHEN 'LOW' THEN 'Low' " +
                    "                    WHEN 'NORMAL' THEN 'Medium' " +
                    "                    WHEN 'MEDIUM' THEN 'Medium' " +
                    "                    WHEN 'HIGH' THEN 'High' " +
                    "                    WHEN 'CRITICAL' THEN 'High' " +
                    "                    ELSE 'Medium' " +
                    "                  END, " +
                    "      'badge', t.user_badge, " +
                    "      'taskSource', t.task_source, " +
                    "      'employees', COALESCE(t.employees, '[]'::jsonb) " +
                    "    ) AS sub " +
                    "    FROM all_todo t " +
                    "    WHERE COALESCE(LOWER(t.status_nm), '') <> 'closed' AND t.st_dt <= v_today " +
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
                    "          'role', CASE " +
                    "                    WHEN t.emp_id = em.emp_id THEN 'Executor' " +
                    "                    WHEN em.emp_id IN (SELECT tm.emp_id FROM team_members tm WHERE tm.task_id = t.task_id) THEN 'Contributor' " +
                    "                    ELSE 'Reviewer/Approver' " +
                    "                  END " +
                    "        )) " +
                    "        FROM employee_master em " +
                    "        WHERE em.emp_id = t.emp_id " +
                    "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.task_id = t.task_id AND pc.is_live = true) " +
                    "           OR em.emp_id IN (SELECT tm.emp_id FROM team_members tm WHERE tm.task_id = t.task_id) " +
                    "      ) AS employees " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "    ) OR t.task_id IN ( " +
                    "      SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
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
                    "          'role', CASE " +
                    "                    WHEN t.emp_id = em.emp_id THEN 'Executor' " +
                    "                    WHEN em.emp_id IN (SELECT tm.emp_id FROM team_members tm WHERE tm.emp_task_id = t.emp_task_id) THEN 'Contributor' " +
                    "                    ELSE 'Reviewer/Approver' " +
                    "                  END " +
                    "        )) " +
                    "        FROM employee_master em " +
                    "        WHERE em.emp_id = t.emp_id " +
                    "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.emp_task_id = t.emp_task_id AND pc.emp_task_id IS NOT NULL) " +
                    "           OR em.emp_id IN (SELECT tm.emp_id FROM team_members tm WHERE tm.emp_task_id = t.emp_task_id) " +
                    "      ) AS employees " +
                    "    FROM employee_individual_task_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( " +
                    "      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL " +
                    "    ) OR t.emp_task_id IN ( " +
                    "      SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL " +
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
                    "    WHERE COALESCE(LOWER(t.status_nm), '') <> 'closed' AND t.st_dt > v_today " +
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
                    "      'openTasks',     COUNT(t.task_id) FILTER (WHERE COALESCE(LOWER(tsm.status_nm), '') <> 'closed'), " +
                    "      'closedTasks',   COUNT(t.task_id) FILTER (WHERE COALESCE(LOWER(tsm.status_nm), '') = 'closed'), " +
                    "      'progress',      ( " +
                    "        SELECT ROUND( " +
                    "          CASE WHEN COUNT(t_all.task_id) > 0 " +
                    "            THEN ( " +
                    "              ( " +
                    "                COUNT(t_all.task_id) FILTER (WHERE COALESCE(LOWER(tsm_all.status_nm), '') = 'closed')::NUMERIC + " +
                    "                COUNT(t_all.task_id) FILTER (WHERE COALESCE(LOWER(tsm_all.status_nm), '') IN ('under review', 'under_review', 'submit review', 'submit_review')) * 0.8 + " +
                    "                COUNT(t_all.task_id) FILTER (WHERE COALESCE(LOWER(tsm_all.status_nm), '') IN ('wip', 'in progress', 'in_progress')) * 0.5 " +
                    "              ) / COUNT(t_all.task_id) " +
                    "            ) * 100 " +
                    "            ELSE 0 END, 0) " +
                    "        FROM task_live_master t_all " +
                    "        JOIN milestone_live_master ml_all ON ml_all.m_id = t_all.m_id " +
                    "        LEFT JOIN task_status_master tsm_all ON tsm_all.status_id = t_all.task_sts " +
                    "        WHERE ml_all.prj_id = p.prj_id " +
                    "          AND (t_all.emp_id = p_emp_id OR t_all.task_id IN ( " +
                    "            SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "          ) OR t_all.task_id IN ( " +
                    "            SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
                    "          )) " +
                    "      ) " +
                    "    ) AS sub " +
                    "    FROM task_live_master t " +
                    "    JOIN milestone_live_master  ml ON ml.m_id   = t.m_id " +
                    "    JOIN project_live_master    p  ON p.prj_id  = ml.prj_id " +
                    "    LEFT JOIN company_master    cm ON cm.coy_id = p.coy_id " +
                    "    LEFT JOIN plant_master      pm ON pm.plt_id = p.plt_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN ( " +
                    "      SELECT DISTINCT ON (prj_id, emp_id) prj_id, emp_id, access_type " +
                    "      FROM project_access " +
                    "      WHERE sts = true " +
                    "    ) pa ON pa.prj_id = p.prj_id AND pa.emp_id = p_emp_id " +
                    "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( " +
                    "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "    ) OR t.task_id IN ( " +
                    "      SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
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
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d AND COALESCE(LOWER(status_nm), '') IN ('open', 'draft', 'hold') AND NOT (end_dt < d OR COALESCE(LOWER(sub_status), '') = 'overdue') AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS open_count, " +
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d AND COALESCE(LOWER(status_nm), '') = 'wip' AND NOT (end_dt < d OR COALESCE(LOWER(sub_status), '') = 'overdue') AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS wip_count, " +
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE (end_dt < d OR sub_status = 'Overdue') AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS overdue_count, " +
                    "        (SELECT COUNT(*) FROM temp_all_tasks WHERE act_cmp_dt <= d) AS completed_count, " +
                    "        (SELECT COUNT(DISTINCT m.prj_id) " +
                    "         FROM task_live_master t_tr " +
                    "         JOIN milestone_live_master m ON m.m_id = t_tr.m_id " +
                    "         JOIN project_live_master p_tr ON p_tr.prj_id = m.prj_id " +
                    "         WHERE (t_tr.emp_id = p_emp_id OR t_tr.task_id IN ( " +
                    "            SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "          ) OR t_tr.task_id IN ( " +
                    "            SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
                    "          )) AND p_tr.prj_sts = 'LIVE' AND p_tr.st_dt <= d) AS projects_count " +

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
                    "        jsonb_agg(assigned_count) AS trend_array, " +
                    "        (SELECT assigned_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        (SELECT assigned_count FROM trend_data ORDER BY d ASC LIMIT 1) AS seven_days_ago_val " +
                    "      FROM trend_data " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'inProgress' AS metric, " +
                    "        jsonb_agg(wip_count) AS trend_array, " +
                    "        (SELECT wip_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        (SELECT wip_count FROM trend_data ORDER BY d ASC LIMIT 1) AS seven_days_ago_val " +
                    "      FROM trend_data " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'openTasks' AS metric, " +
                    "        jsonb_agg(open_count) AS trend_array, " +
                    "        (SELECT open_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        (SELECT open_count FROM trend_data ORDER BY d ASC LIMIT 1) AS seven_days_ago_val " +
                    "      FROM trend_data " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'overdueTasks' AS metric, " +
                    "        jsonb_agg(overdue_count) AS trend_array, " +
                    "        (SELECT overdue_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        (SELECT overdue_count FROM trend_data ORDER BY d ASC LIMIT 1) AS seven_days_ago_val " +
                    "      FROM trend_data " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'completedTasks' AS metric, " +
                    "        jsonb_agg(completed_count) AS trend_array, " +
                    "        (SELECT completed_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        (SELECT completed_count FROM trend_data ORDER BY d ASC LIMIT 1) AS seven_days_ago_val " +
                    "      FROM trend_data " +
                    "      UNION ALL " +
                    "      SELECT " +
                    "        'myProjects' AS metric, " +
                    "        jsonb_agg(projects_count) AS trend_array, " +
                    "        (SELECT projects_count FROM trend_data WHERE d = v_today) AS current_val, " +
                    "        (SELECT projects_count FROM trend_data ORDER BY d ASC LIMIT 1) AS seven_days_ago_val " +
                    "      FROM trend_data " +
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
                    "      ) OR t.task_id IN ( " +
                    "         SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
                    "      ) OR ind.emp_task_id IN ( " +
                    "         SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL " +
                    "      ))) " +
                    "      OR (p.prj_id IN ( " +
                    "         SELECT DISTINCT ml_sub.prj_id " +
                    "         FROM task_live_master t_sub " +
                    "         JOIN milestone_live_master ml_sub ON ml_sub.m_id = t_sub.m_id " +
                    "         WHERE t_sub.emp_id = p_emp_id OR t_sub.task_id IN ( " +
                    "           SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true " +
                    "         ) OR t_sub.task_id IN ( " +
                    "           SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL " +
                    "         ) " +
                    "      )) " +
                    "    ORDER BY al.log_dt DESC " +
                    "    LIMIT 5 " +
                    "  ) x; " +
                    " " +
                    "  /* 10. Performance Calculations */ " +
                    "  SELECT COALESCE( " +
                    "    ROUND( " +
                    "      (COUNT(*) FILTER (WHERE COALESCE(LOWER(status_nm), '') = 'closed' AND (act_cmp_dt IS NULL OR act_cmp_dt <= end_dt))::NUMERIC / " +
                    "       NULLIF(v_total_tasks, 0)) * 100, " +
                    "      0 " +
                    "    )::INT, " +
                    "    100 " +
                    "  ) INTO v_on_time_delivery " +
                    "  FROM temp_all_tasks; " +
                    " " +
                    "  v_productivity := CASE WHEN v_total_tasks > 0 THEN GREATEST(0, 100 - ROUND((v_overdue::NUMERIC / v_total_tasks) * 100, 0)::INT) ELSE 100 END; " +
                    " " +
                    "  v_quality := ROUND((v_productivity + v_on_time_delivery) / 2.0)::INT; " +
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
                    "      'score', v_on_time_delivery, " +
                    "      'rating', CASE " +
                    "                  WHEN v_on_time_delivery >= 90 THEN 'Excellent' " +
                    "                  WHEN v_on_time_delivery >= 75 THEN 'Good' " +
                    "                  WHEN v_on_time_delivery >= 50 THEN 'Satisfactory' " +
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
                    "      'Closed', v_completed, 'In Progress', v_wip, " +
                    "      'Under Review', v_under_review, 'Overdue', v_overdue, " +
                    "      'Open', v_open, 'Reassigned', v_reassigned, " +
                    "      'Rework', v_rework, 'Draft', v_draft, " +
                    "      'MainClosed', v_main_completed, 'MainWIP', v_main_wip, " +
                    "      'MainOpen', v_main_open), " +
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

            // 2d_new. Create/Update get_my_tasks_data SQL function
            try {
                System.out.println("Creating/Updating get_my_tasks_data stored procedure...");
                stmt.execute(
                    "CREATE OR REPLACE FUNCTION get_my_tasks_data(p_emp_id BIGINT) " +
                    "RETURNS jsonb " +
                    "LANGUAGE plpgsql " +
                    "SECURITY DEFINER " +
                    "AS $$ " +
                    "DECLARE " +
                    "  v_today          DATE := CURRENT_DATE; " +
                    "  v_tasks          jsonb; " +
                    "BEGIN " +
                    "  WITH combined_tasks AS ( " +
                    "    SELECT " +
                    "      t.task_id AS task_id, " +
                    "      t.task_cd AS task_cd, " +
                    "      t.task_nm AS task_nm, " +
                    "      t.task_desc AS task_desc, " +
                    "      t.task_asgn_to AS task_asgn_to, " +
                    "      t.emp_id AS emp_id, " +
                    "      t.ext_emp_id AS ext_emp_id, " +
                    "      t.task_dep_flg AS task_dep_flg, " +
                    "      t.task_dep_typ AS task_dep_typ, " +
                    "      t.dep_task_id AS dep_task_id, " +
                    "      t.no_of_days AS no_of_days, " +
                    "      t.wrk_days AS wrk_days, " +
                    "      t.chk_flg AS chk_flg, " +
                    "      t.atta_flg AS atta_flg, " +
                    "      t.atta_file_id AS atta_file_id, " +
                    "      t.note_txt AS note_txt, " +
                    "      t.st_dt AS st_dt, " +
                    "      t.end_dt AS end_dt, " +
                    "      t.act_cmp_dt AS act_cmp_dt, " +
                    "      t.prcs_flg AS prcs_flg, " +
                    "      t.prcs_yes_actn AS prcs_yes_actn, " +
                    "      tsm.status_nm AS status_nm, " +
                    "      t.sub_status AS sub_status, " +
                    "      pm.priority_nm AS priority_nm, " +
                    "      t.addl_rem AS addl_rem, " +
                    "      false AS is_individual, " +
                    "      p.prj_nm AS project_name, " +
                    "      m.mlstn_ttl AS milestone_title, " +
                    "      pc_rev.emp_id AS reviewer_id, " +
                    "      TRIM(COALESCE(e_rev.fst_nm,'')||' '||COALESCE(e_rev.lst_nm,'')) AS reviewer_name, " +
                    "      pc_app.emp_id AS approver_id, " +
                    "      TRIM(COALESCE(e_app.fst_nm,'')||' '||COALESCE(e_app.lst_nm,'')) AS approver_name, " +
                    "      chk.total AS chk_total, " +
                    "      chk.completed AS chk_completed " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id " +
                    "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    LEFT JOIN process_config pc_rev ON pc_rev.task_id = t.task_id AND pc_rev.is_live = true AND pc_rev.ordr_id = 1 " +
                    "    LEFT JOIN employee_master e_rev ON e_rev.emp_id = pc_rev.emp_id " +
                    "    LEFT JOIN process_config pc_app ON pc_app.task_id = t.task_id AND pc_app.is_live = true AND pc_app.ordr_id = 2 " +
                    "    LEFT JOIN employee_master e_app ON e_app.emp_id = pc_app.emp_id " +
                    "    LEFT JOIN LATERAL ( " +
                    "      SELECT " +
                    "        COALESCE(SUM(1 + LENGTH(chk_nm) - LENGTH(REPLACE(chk_nm, ',', ''))), 0) AS total, " +
                    "        COALESCE(SUM(CASE WHEN chk_sts = true THEN 1 + LENGTH(chk_nm) - LENGTH(REPLACE(chk_nm, ',', '')) ELSE 0 END), 0) AS completed " +
                    "      FROM checklist_master " +
                    "      WHERE task_id = t.task_id AND sts = true " +
                    "    ) chk ON true " +
                    "    WHERE (t.emp_id = p_emp_id OR pc_rev.emp_id = p_emp_id OR pc_app.emp_id = p_emp_id OR t.task_id IN (SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL)) " +
                    " " +
                    "    UNION ALL " +
                    " " +
                    "    SELECT " +
                    "      t.emp_task_id AS task_id, " +
                    "      t.task_cd AS task_cd, " +
                    "      t.task_nm AS task_nm, " +
                    "      t.task_desc AS task_desc, " +
                    "      t.task_asgn_to AS task_asgn_to, " +
                    "      t.emp_id AS emp_id, " +
                    "      NULL::bigint AS ext_emp_id, " +
                    "      false AS task_dep_flg, " +
                    "      NULL::varchar AS task_dep_typ, " +
                    "      NULL::bigint AS dep_task_id, " +
                    "      (t.end_dt - t.st_dt) AS no_of_days, " +
                    "      NULL::integer AS wrk_days, " +
                    "      t.chk_flg AS chk_flg, " +
                    "      t.atta_flg AS atta_flg, " +
                    "      NULL::integer AS atta_file_id, " +
                    "      NULL::varchar AS note_txt, " +
                    "      t.st_dt AS st_dt, " +
                    "      t.end_dt AS end_dt, " +
                    "      CASE WHEN tsm.status_nm = 'Closed' THEN t.end_dt ELSE NULL END AS act_cmp_dt, " +
                    "      t.prcs_flg AS prcs_flg, " +
                    "      t.prcs_yes_actn AS prcs_yes_actn, " +
                    "      tsm.status_nm AS status_nm, " +
                    "      t.sub_status AS sub_status, " +
                    "      pm.priority_nm AS priority_nm, " +
                    "      t.remarks AS addl_rem, " +
                    "      true AS is_individual, " +
                    "      'Individual Task' AS project_name, " +
                    "      '-' AS milestone_title, " +
                    "      pc_rev.emp_id AS reviewer_id, " +
                    "      TRIM(COALESCE(e_rev.fst_nm,'')||' '||COALESCE(e_rev.lst_nm,'')) AS reviewer_name, " +
                    "      pc_app.emp_id AS approver_id, " +
                    "      TRIM(COALESCE(e_app.fst_nm,'')||' '||COALESCE(e_app.lst_nm,'')) AS approver_name, " +
                    "      chk.total AS chk_total, " +
                    "      chk.completed AS chk_completed " +
                    "    FROM employee_individual_task_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority " +
                    "    LEFT JOIN process_config pc_rev ON pc_rev.emp_task_id = t.emp_task_id AND pc_rev.ordr_id = 1 " +
                    "    LEFT JOIN employee_master e_rev ON e_rev.emp_id = pc_rev.emp_id " +
                    "    LEFT JOIN process_config pc_app ON pc_app.emp_task_id = t.emp_task_id AND pc_app.ordr_id = 2 " +
                    "    LEFT JOIN employee_master e_app ON e_app.emp_id = pc_app.emp_id " +
                    "    LEFT JOIN LATERAL ( " +
                    "      SELECT " +
                    "        COALESCE(SUM(1 + LENGTH(chk_nm) - LENGTH(REPLACE(chk_nm, ',', ''))), 0) AS total, " +
                    "        COALESCE(SUM(CASE WHEN chk_sts = true THEN 1 + LENGTH(chk_nm) - LENGTH(REPLACE(chk_nm, ',', '')) ELSE 0 END), 0) AS completed " +
                    "      FROM checklist_master " +
                    "      WHERE emp_task_id = t.emp_task_id AND sts = true " +
                    "    ) chk ON true " +
                    "    WHERE COALESCE(t.sts, true) = true AND (t.emp_id = p_emp_id OR pc_rev.emp_id = p_emp_id OR pc_app.emp_id = p_emp_id OR t.emp_task_id IN (SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL)) " +
                    "  ), " +
                    "  calculated_tasks AS ( " +
                    "    SELECT " +
                    "      t.*, " +
                    "      CASE " +
                    "        WHEN t.priority_nm IS NOT NULL THEN " +
                    "          CASE " +
                    "            WHEN UPPER(t.priority_nm) = 'LOW' THEN 'Low' " +
                    "            WHEN UPPER(t.priority_nm) = 'NORMAL' THEN 'Normal' " +
                    "            WHEN UPPER(t.priority_nm) = 'MEDIUM' THEN 'Medium' " +
                    "            WHEN UPPER(t.priority_nm) = 'HIGH' THEN 'High' " +
                    "            WHEN UPPER(t.priority_nm) IN ('CRITICAL', 'ATMOST CRITICAL') THEN 'Critical' " +
                    "            ELSE t.priority_nm " +
                    "          END " +
                    "        WHEN t.end_dt IS NOT NULL THEN " +
                    "          CASE " +
                    "            WHEN ( " +
                    "              COALESCE( " +
                    "                CASE WHEN t.status_nm IN ('CLOSED', 'COMPLETED', 'UNDER_REVIEW', 'SUBMIT_REVIEW') " +
                    "                     THEN COALESCE(t.act_cmp_dt, v_today) " +
                    "                     ELSE v_today " +
                    "                END, v_today) - t.end_dt " +
                    "            ) = 0 THEN 'High' " +
                    "            WHEN ( " +
                    "              COALESCE( " +
                    "                CASE WHEN t.status_nm IN ('CLOSED', 'COMPLETED', 'UNDER_REVIEW', 'SUBMIT_REVIEW') " +
                    "                     THEN COALESCE(t.act_cmp_dt, v_today) " +
                    "                     ELSE v_today " +
                    "                END, v_today) - t.end_dt " +
                    "            ) = 1 THEN 'Critical' " +
                    "            WHEN ( " +
                    "              COALESCE( " +
                    "                CASE WHEN t.status_nm IN ('CLOSED', 'COMPLETED', 'UNDER_REVIEW', 'SUBMIT_REVIEW') " +
                    "                     THEN COALESCE(t.act_cmp_dt, v_today) " +
                    "                     ELSE v_today " +
                    "                END, v_today) - t.end_dt " +
                    "            ) >= 2 THEN 'Critical' " +
                    "            ELSE 'Low' " +
                    "          END " +
                    "        ELSE 'Medium' " +
                    "      END AS final_priority, " +
                    "      CASE " +
                    "        WHEN UPPER(t.status_nm) IN ('CLOSED', 'COMPLETED') THEN 'Closed' " +
                    "        WHEN UPPER(t.status_nm) = 'HOLD' THEN 'Hold' " +
                    "        WHEN UPPER(t.status_nm) = 'DRAFT' THEN 'Draft' " +
                    "        WHEN UPPER(t.status_nm) IN ('WIP', 'IN_PROGRESS', 'UNDER_REVIEW', 'SUBMIT_REVIEW') THEN 'In Progress' " +
                    "        ELSE 'Open' " +
                    "      END AS progress_sts, " +
                    "      CASE " +
                    "        WHEN t.sub_status = 'Under Review' OR UPPER(t.status_nm) IN ('UNDER_REVIEW', 'SUBMIT_REVIEW') THEN 'Under Review' " +
                    "        WHEN t.sub_status = 'Rework' OR UPPER(t.status_nm) = 'REWORK' THEN 'Rework' " +
                    "        WHEN t.sub_status = 'Reassign' OR UPPER(t.status_nm) = 'REASSIGN' THEN 'Reassign' " +
                    "        ELSE 'None' " +
                    "      END AS process_sts, " +
                    "      CASE " +
                    "        WHEN UPPER(t.status_nm) IN ('CLOSED', 'COMPLETED') THEN " +
                    "          CASE " +
                    "            WHEN t.end_dt IS NOT NULL THEN " +
                    "              CASE " +
                    "                WHEN COALESCE(t.act_cmp_dt, v_today) < t.end_dt THEN 'Lead' " +
                    "                WHEN COALESCE(t.act_cmp_dt, v_today) = t.end_dt THEN 'On Time' " +
                    "                ELSE 'Lag' " +
                    "              END " +
                    "            ELSE 'On Time' " +
                    "          END " +
                    "        ELSE " +
                    "          CASE " +
                    "            WHEN t.end_dt IS NOT NULL THEN " +
                    "              CASE " +
                    "                WHEN v_today < t.end_dt THEN 'On Time' " +
                    "                WHEN v_today = t.end_dt THEN 'Due Today' " +
                    "                ELSE 'Overdue' " +
                    "              END " +
                    "            ELSE 'On Time' " +
                    "          END " +
                    "      END AS time_sts " +
                    "    FROM combined_tasks t " +
                    "  ), " +
                    "  final_tasks AS ( " +
                    "    SELECT " +
                    "      t.*, " +
                    "      CASE " +
                    "        WHEN NOT COALESCE(t.prcs_flg, false) THEN " +
                    "          CASE " +
                    "            WHEN UPPER(t.status_nm) IN ('CLOSED', 'COMPLETED') THEN 100 " +
                    "            WHEN t.chk_total > 0 THEN ROUND((t.chk_completed::numeric / t.chk_total) * 100)::integer " +
                    "            ELSE 0 " +
                    "          END " +
                    "        ELSE " +
                    "          CASE " +
                    "            WHEN UPPER(t.status_nm) IN ('CLOSED', 'COMPLETED') THEN 100 " +
                    "            WHEN UPPER(t.status_nm) = 'UNDER_REVIEW' THEN 95 " +
                    "            WHEN UPPER(t.status_nm) = 'SUBMIT_REVIEW' THEN 90 " +
                    "            WHEN t.chk_total > 0 THEN ROUND((t.chk_completed::numeric / t.chk_total) * 100)::integer " +
                    "            ELSE 0 " +
                    "          END " +
                    "      END AS progress_pct " +
                    "    FROM calculated_tasks t " +
                    "  ) " +
                    "  SELECT COALESCE(jsonb_agg( " +
                    "    jsonb_build_object( " +
                    "      'id', COALESCE(t.task_cd, CASE WHEN t.is_individual THEN 'IND-' || t.task_id ELSE 'TSK-' || t.task_id END), " +
                    "      'taskId', t.task_id, " +
                    "      'isIndividual', t.is_individual, " +
                    "      'title', t.task_nm, " +
                    "      'project', COALESCE(t.project_name, 'Unknown Project'), " +
                    "      'milestone', COALESCE(t.milestone_title, 'Unknown Milestone'), " +
                    "      'priority', t.final_priority, " +
                    "      'dueDate', COALESCE(t.end_dt::text, ''), " +
                    "      'status', t.progress_sts, " +
                    "      'progressSts', t.progress_sts, " +
                    "      'processSts', t.process_sts, " +
                    "      'timeSts', t.time_sts, " +
                    "      'progress', t.progress_pct, " +
                    "      'rawStatus', t.status_nm, " +
                    "      'description', COALESCE(t.task_desc, ''), " +
                    "      'assignedBy', CASE WHEN t.is_individual THEN 'Task Manager' ELSE 'Project Manager' END, " +
                    "      'rawTask', jsonb_build_object( " +
                    "        'taskId', t.task_id, " +
                    "        'mId', CASE WHEN t.is_individual THEN NULL ELSE t.task_id END, " +
                    "        'taskCd', t.task_cd, " +
                    "        'taskNm', t.task_nm, " +
                    "        'taskDesc', t.task_desc, " +
                    "        'empId', t.emp_id, " +
                    "        'extEmpId', t.ext_emp_id, " +
                    "        'taskDepFlg', t.task_dep_flg, " +
                    "        'taskDepTyp', t.task_dep_typ, " +
                    "        'depTaskId', t.dep_task_id, " +
                    "        'noOfDays', t.no_of_days, " +
                    "        'wrkDays', t.wrk_days, " +
                    "        'chkFlg', t.chk_flg, " +
                    "        'attaFlg', t.atta_flg, " +
                    "        'attaFileId', t.atta_file_id, " +
                    "        'noteTxt', t.note_txt, " +
                    "        'stDt', COALESCE(t.st_dt::text, ''), " +
                    "        'endDt', COALESCE(t.end_dt::text, ''), " +
                    "        'actCmpDt', COALESCE(t.act_cmp_dt::text, ''), " +
                    "        'prcsFlg', t.prcs_flg, " +
                    "        'prcsYesActn', t.prcs_yes_actn, " +
                    "        'taskSts', t.status_nm, " +
                    "        'subStatus', t.sub_status, " +
                    "        'priority', t.priority_nm, " +
                    "        'addlRem', t.addl_rem, " +
                    "        'reviewerId', t.reviewer_id, " +
                    "        'approverId', t.approver_id, " +
                    "        'reviewerNm', t.reviewer_name, " +
                    "        'approverNm', t.approver_name " +
                    "      ) " +
                    "    ) " +
                    "  ), '[]'::jsonb) INTO v_tasks " +
                    "  FROM final_tasks t; " +
                    " " +
                    "  RETURN v_tasks; " +
                    "END; " +
                    "$$;"
                );
                System.out.println("get_my_tasks_data stored procedure created/updated successfully.");
            } catch (Exception e) {
                System.err.println("Failed to create/update get_my_tasks_data stored procedure: " + e.getMessage());
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
                    "  FOR rec IN " +
                    "    SELECT t.task_sts, t.end_dt, tsm.status_nm, t.sub_status " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "  LOOP " +
                    "    v_t_total := v_t_total + 1; " +
                    "    IF rec.status_nm IN ('Closed', 'Completed') THEN " +
                    "      v_t_completed := v_t_completed + 1; " +
                    "    ELSIF rec.status_nm = 'WIP' THEN " +
                    "      v_t_in_prog := v_t_in_prog + 1; " +
                    "    ELSE " +
                    "      v_t_todo := v_t_todo + 1; " +
                    "    END IF; " +
                    " " +
                    "    IF rec.status_nm NOT IN ('Closed', 'Completed') AND (rec.sub_status = 'Overdue' OR (rec.end_dt IS NOT NULL AND rec.end_dt < v_today)) THEN " +
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
                    "        THEN (COUNT(t.task_id) FILTER (WHERE tsm.status_nm IN ('Closed', 'Completed'))::NUMERIC/COUNT(t.task_id))*100 " +
                    "        ELSE 0 END, 2) " +
                    "    ) AS sub " +
                    "    FROM project_live_master p " +
                    "    LEFT JOIN milestone_live_master m ON m.prj_id = p.prj_id " +
                    "    LEFT JOIN task_live_master t ON t.m_id = m.m_id " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
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
                    "    WHERE t.task_sts <> 4 AND t.end_dt IS NOT NULL " +
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
                    "              WHEN tsm.status_nm = 'Completed' THEN 100.0 " +
                    "              WHEN tsm.status_nm = 'WIP' AND t.sub_status = 'Under Review' THEN 80.0 " +
                    "              WHEN tsm.status_nm = 'WIP' AND t.sub_status = 'Rework' THEN 20.0 " +
                    "              WHEN tsm.status_nm = 'WIP' THEN 50.0 " +
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
                    "  FOR rec IN " +
                    "    SELECT t.task_sts, t.end_dt, tsm.status_nm, t.sub_status " +
                    "    FROM task_live_master t " +
                    "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts " +
                    "  LOOP " +
                    "    v_t_total := v_t_total + 1; " +
                    "    IF rec.status_nm = 'Completed' THEN " +
                    "      v_t_completed := v_t_completed + 1; " +
                    "    ELSIF rec.sub_status = 'Overdue' OR (rec.status_nm <> 'Completed' AND rec.end_dt IS NOT NULL AND rec.end_dt < v_today) THEN " +
                    "      v_t_overdue := v_t_overdue + 1; " +
                    "    ELSIF rec.status_nm = 'WIP' AND rec.sub_status = 'Under Review' THEN " +
                    "      v_t_under_review := v_t_under_review + 1; " +
                    "    ELSIF rec.status_nm = 'WIP' THEN " +
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
                    "    WHERE t.task_sts <> 4 AND t.end_dt >= v_today " +
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

            try {
                stmt.execute("RESET lock_timeout");
            } catch (Exception e) {}
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
