package com.bionova.config;

import java.io.FileWriter;

public class SQLPrinter {
    public static void main(String[] args) throws Exception {
        // Source: D:\sample\db-query-scratch\db_user_dashboard_current.sql (31-07-2026)
        // This is the exact working stored procedure — do NOT modify status filters here.
        // Status values in DB: 'CLOSED', 'COMPLETED', 'WIP', 'IN PROGRESS', 'OPEN', 'OVER_DUE', 'DRAFT'
        // sub_status values: 'UNDER REVIEW', 'REASSIGN', 'REWORK'
        String sql =
            "CREATE OR REPLACE FUNCTION public.get_user_dashboard(p_emp_id bigint)\n" +
            " RETURNS jsonb\n" +
            " LANGUAGE plpgsql\n" +
            " SECURITY DEFINER\n" +
            "AS $function$ \n" +
            "DECLARE \n" +
            "  v_today          DATE := CURRENT_DATE; \n" +
            "  v_emp            RECORD; \n" +
            "  v_full_name      TEXT; \n" +
            "  v_total_tasks    INT := 0; \n" +
            "  v_completed      INT := 0; \n" +
            "  v_overdue        INT := 0; \n" +
            "  v_due_today      INT := 0; \n" +
            "  v_wip            INT := 0; \n" +
            "  v_under_review   INT := 0; \n" +
            "  v_open           INT := 0; \n" +
            "  v_reassigned     INT := 0; \n" +
            "  v_rework         INT := 0; \n" +
            "  v_draft          INT := 0; \n" +
            "  v_my_prj_count   BIGINT := 0; \n" +
            "  v_todo_list      jsonb; \n" +
            "  v_upcoming       jsonb; \n" +
            "  v_my_projects    jsonb; \n" +
            "  v_metrics_trends jsonb; \n" +
            "  v_recent_activity jsonb; \n" +
            "  v_performance    jsonb; \n" +
            "  v_productivity   INT := 100; \n" +
            "  v_quality        INT := 100; \n" +
            "BEGIN \n" +
            "  /* 1. Employee Profile Details */ \n" +
            "  SELECT em.emp_id, em.fst_nm, em.lst_nm, em.photo_url, \n" +
            "         dm.desig_nm, dept.dept_nm \n" +
            "  INTO v_emp \n" +
            "  FROM employee_master em \n" +
            "  LEFT JOIN designation_master dm   ON dm.desig_id = em.desig_id \n" +
            "  LEFT JOIN department_master  dept ON dept.dept_id = em.dept_id \n" +
            "  WHERE em.emp_id = p_emp_id; \n" +
            "\n" +
            "  v_full_name := TRIM(COALESCE(v_emp.fst_nm,'')||' '||COALESCE(v_emp.lst_nm,'')); \n" +
            "\n" +
            "  /* 2. Task Counts from BOTH project tasks and individual assignments using Temporary Table */ \n" +
            "  DROP TABLE IF EXISTS temp_all_tasks; \n" +
            "  CREATE TEMPORARY TABLE temp_all_tasks ON COMMIT DROP AS \n" +
            "    SELECT DISTINCT ON (t.task_id)\n" +
            "      t.task_id, \n" +
            "      t.task_nm, \n" +
            "      t.st_dt, \n" +
            "      t.end_dt, \n" +
            "      COALESCE(t.act_cmp_dt, CASE WHEN UPPER(tsm.status_nm) IN ('CLOSED', 'COMPLETED') THEN t.end_dt ELSE NULL END) AS act_cmp_dt, \n" +
            "      t.no_of_days, \n" +
            "      t.task_sts, \n" +
            "      tsm.status_nm, \n" +
            "      t.sub_status,\n" +
            "      COALESCE(p.prj_cd || ' - ' || m.mlstn_ttl, '') AS project_info, \n" +
            "      COALESCE(p.prj_cd, '') AS prj_cd, \n" +
            "      CASE \n" +
            "        WHEN t.emp_id = p_emp_id THEN 'Executor' \n" +
            "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true AND pc.ordr_id = 1) THEN 'Reviewer' \n" +
            "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true AND pc.ordr_id = 2) THEN 'Approver' \n" +
            "        ELSE 'Executor' \n" +
            "      END AS user_badge, \n" +
            "      pm.priority_nm, \n" +
            "      'PROJECT' AS task_source \n" +
            "    FROM task_live_master t \n" +
            "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id \n" +
            "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id \n" +
            "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts \n" +
            "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority \n" +
            "    WHERE (\n" +
            "      t.emp_id = p_emp_id \n" +
            "      OR t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true)\n" +
            "      OR t.task_id IN (SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL)\n" +
            "    ) \n" +
            "    AND COALESCE(UPPER(tsm.status_nm), '') <> 'DRAFT' \n" +
            "    AND (t.st_dt IS NULL OR t.st_dt <= v_today OR UPPER(tsm.status_nm) IN ('CLOSED', 'COMPLETED'))\n" +
            " \n" +
            "    UNION ALL \n" +
            " \n" +
            "    SELECT DISTINCT ON (t.emp_task_id)\n" +
            "      t.emp_task_id AS task_id, \n" +
            "      t.task_nm, \n" +
            "      t.st_dt, \n" +
            "      t.end_dt, \n" +
            "      CASE WHEN UPPER(tsm.status_nm) IN ('CLOSED', 'COMPLETED') THEN t.end_dt ELSE NULL END AS act_cmp_dt, \n" +
            "      (t.end_dt - t.st_dt) AS no_of_days, \n" +
            "      t.task_sts, \n" +
            "      tsm.status_nm, \n" +
            "      t.sub_status,\n" +
            "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS project_info, \n" +
            "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS prj_cd, \n" +
            "      CASE \n" +
            "        WHEN t.emp_id = p_emp_id THEN 'Executor' \n" +
            "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 1) THEN 'Reviewer' \n" +
            "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 2) THEN 'Approver' \n" +
            "        ELSE 'Executor' \n" +
            "      END AS user_badge, \n" +
            "      pm.priority_nm, \n" +
            "      'INDIVIDUAL' AS task_source \n" +
            "    FROM employee_individual_task_master t \n" +
            "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts \n" +
            "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority \n" +
            "    WHERE COALESCE(t.sts, true) = true \n" +
            "    AND (\n" +
            "      t.emp_id = p_emp_id \n" +
            "      OR t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL)\n" +
            "      OR t.emp_task_id IN (SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL)\n" +
            "    ) \n" +
            "    AND COALESCE(UPPER(tsm.status_nm), '') <> 'DRAFT' \n" +
            "    AND (t.st_dt IS NULL OR t.st_dt <= v_today OR UPPER(tsm.status_nm) IN ('CLOSED', 'COMPLETED'))\n" +
            "  ; \n" +
            " \n" +
            "  SELECT \n" +
            "    COUNT(*), \n" +
            "    COUNT(*) FILTER (WHERE UPPER(status_nm) IN ('CLOSED', 'COMPLETED')), \n" +
            "    COUNT(*) FILTER (WHERE UPPER(status_nm) = 'OVER_DUE' OR (UPPER(status_nm) NOT IN ('CLOSED', 'COMPLETED') AND end_dt IS NOT NULL AND end_dt < v_today)), \n" +
            "    COUNT(*) FILTER (WHERE UPPER(status_nm) NOT IN ('CLOSED', 'COMPLETED') AND end_dt = v_today), \n" +
            "    COUNT(*) FILTER (WHERE (UPPER(status_nm) = 'WIP' OR UPPER(status_nm) = 'IN PROGRESS')), \n" +
            "    COUNT(*) FILTER (WHERE (UPPER(status_nm) = 'WIP' OR UPPER(status_nm) = 'IN PROGRESS') AND UPPER(sub_status) = 'UNDER REVIEW'), \n" +
            "    COUNT(*) FILTER (WHERE UPPER(status_nm) = 'OPEN' OR status_nm IS NULL), \n" +
            "    COUNT(*) FILTER (WHERE (UPPER(status_nm) = 'WIP' OR UPPER(status_nm) = 'IN PROGRESS') AND UPPER(sub_status) = 'REASSIGN'), \n" +
            "    COUNT(*) FILTER (WHERE (UPPER(status_nm) = 'WIP' OR UPPER(status_nm) = 'IN PROGRESS') AND UPPER(sub_status) = 'REWORK'), \n" +
            "    COUNT(*) FILTER (WHERE UPPER(status_nm) = 'DRAFT') \n" +
            "  INTO v_total_tasks, v_completed, v_overdue, v_due_today, \n" +
            "       v_wip, v_under_review, v_open, v_reassigned, v_rework, v_draft \n" +
            "  FROM temp_all_tasks; \n" +
            "\n" +
            "  /* 3. Projects Count (Only active projects) */ \n" +
            "  SELECT COUNT(DISTINCT m.prj_id) INTO v_my_prj_count \n" +
            "  FROM task_live_master t \n" +
            "  JOIN milestone_live_master m ON m.m_id = t.m_id \n" +
            "  JOIN project_live_master p ON p.prj_id = m.prj_id \n" +
            "  WHERE (t.emp_id = p_emp_id OR t.task_id IN ( \n" +
            "    SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true\n" +
            "  ) OR t.task_id IN (\n" +
            "    SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL\n" +
            "  )) AND p.prj_sts = 'LIVE'; \n" +
            "\n" +
            "  /* 4. To-Do List (Limit 5, ordered by end_dt) */ \n" +
            "  WITH all_todo AS ( \n" +
            "    SELECT \n" +
            "      t.task_id, \n" +
            "      t.task_cd,\n" +
            "      t.task_nm, \n" +
            "      t.st_dt, \n" +
            "      t.end_dt, \n" +
            "      t.task_sts, \n" +
            "      tsm.status_nm, \n" +
            "      COALESCE(p.prj_cd || ' - ' || m.mlstn_ttl, '') AS project_info, \n" +
            "      CASE \n" +
            "        WHEN t.emp_id = p_emp_id THEN 'Executor' \n" +
            "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true AND pc.ordr_id = 1) THEN 'Reviewer' \n" +
            "        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true AND pc.ordr_id = 2) THEN 'Approver' \n" +
            "        ELSE 'Executor' \n" +
            "      END AS user_badge, \n" +
            "      pm.priority_nm, \n" +
            "      'PROJECT' AS task_source,\n" +
            "      ( \n" +
            "        SELECT jsonb_agg(jsonb_build_object( \n" +
            "          'empId', em.emp_id, \n" +
            "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), \n" +
            "          'photoUrl', em.photo_url, \n" +
            "          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END \n" +
            "        )) \n" +
            "        FROM employee_master em \n" +
            "        WHERE em.emp_id = t.emp_id \n" +
            "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.task_id = t.task_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true) \n" +
            "      ) AS employees \n" +
            "    FROM task_live_master t \n" +
            "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id \n" +
            "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id \n" +
            "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts \n" +
            "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority \n" +
            "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( \n" +
            "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true\n" +
            "    ) OR t.task_id IN (\n" +
            "      SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL\n" +
            "    )) \n" +
            "\n" +
            "    UNION ALL \n" +
            "\n" +
            "    SELECT \n" +
            "      t.emp_task_id AS task_id, \n" +
            "      t.task_cd,\n" +
            "      t.task_nm, \n" +
            "      t.st_dt, \n" +
            "      t.end_dt, \n" +
            "      t.task_sts, \n" +
            "      tsm.status_nm, \n" +
            "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS project_info, \n" +
            "      CASE \n" +
            "        WHEN t.emp_id = p_emp_id THEN 'Executor' \n" +
            "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 1) THEN 'Reviewer' \n" +
            "        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 2) THEN 'Approver' \n" +
            "        ELSE 'Executor' \n" +
            "      END AS user_badge, \n" +
            "      pm.priority_nm, \n" +
            "      'INDIVIDUAL' AS task_source,\n" +
            "      ( \n" +
            "        SELECT jsonb_agg(jsonb_build_object( \n" +
            "          'empId', em.emp_id, \n" +
            "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), \n" +
            "          'photoUrl', em.photo_url, \n" +
            "          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END \n" +
            "        )) \n" +
            "        FROM employee_master em \n" +
            "        WHERE em.emp_id = t.emp_id \n" +
            "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.emp_task_id = t.emp_task_id AND pc.emp_task_id IS NOT NULL) \n" +
            "      ) AS employees \n" +
            "    FROM employee_individual_task_master t \n" +
            "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts \n" +
            "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority \n" +
            "    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( \n" +
            "      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL\n" +
            "    ) OR t.emp_task_id IN (\n" +
            "      SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL\n" +
            "    )) AND COALESCE(t.sts, true) = true \n" +
            "  ) \n" +
            "  SELECT jsonb_agg(sub) INTO v_todo_list \n" +
            "  FROM ( \n" +
            "    SELECT jsonb_build_object( \n" +
            "      'taskId', t.task_id, \n" +
            "      'taskCode', COALESCE(t.task_cd, CASE WHEN t.task_source = 'INDIVIDUAL' THEN 'IND-' || t.task_id ELSE 'TSK-' || t.task_id END),\n" +
            "      'taskNm', t.task_nm, \n" +
            "      'project', t.project_info, \n" +
            "      'endDt', t.end_dt, \n" +
            "      'status', t.status_nm, \n" +
            "      'isOverdue', (UPPER(t.status_nm) = 'OVER_DUE' OR (UPPER(t.status_nm) NOT IN ('COMPLETED', 'CLOSED') AND t.end_dt < v_today)), \n" +
            "      'isDueToday', (UPPER(t.status_nm) NOT IN ('COMPLETED', 'CLOSED') AND t.end_dt = v_today), \n" +
            "      'priority', CASE COALESCE(t.priority_nm, 'MEDIUM') \n" +
            "                    WHEN 'LOW' THEN 'Low' \n" +
            "                    WHEN 'NORMAL' THEN 'Medium' \n" +
            "                    WHEN 'MEDIUM' THEN 'Medium' \n" +
            "                    WHEN 'HIGH' THEN 'High' \n" +
            "                    WHEN 'CRITICAL' THEN 'High' \n" +
            "                    ELSE 'Medium' \n" +
            "                  END, \n" +
            "      'badge', t.user_badge, \n" +
            "      'taskSource', t.task_source,\n" +
            "      'employees', COALESCE(t.employees, '[]'::jsonb) \n" +
            "    ) AS sub \n" +
            "    FROM all_todo t \n" +
            "    WHERE UPPER(COALESCE(t.status_nm, '')) NOT IN ('COMPLETED', 'CLOSED') \n" +
            "      AND (t.st_dt IS NULL OR t.st_dt <= v_today) \n" +
            "    ORDER BY t.end_dt ASC NULLS LAST \n" +
            "    LIMIT 5 \n" +
            "  ) x; \n" +
            "\n" +
            "  /* 5. Upcoming Tasks (Limit 5, ordered by end_dt) */ \n" +
            "  WITH all_upcoming AS ( \n" +
            "    SELECT \n" +
            "      t.task_id, \n" +
            "      t.task_cd,\n" +
            "      t.task_nm, \n" +
            "      t.st_dt, \n" +
            "      t.end_dt, \n" +
            "      t.no_of_days, \n" +
            "      t.task_sts, \n" +
            "      tsm.status_nm, \n" +
            "      COALESCE(p.prj_cd, '') AS prj_cd, \n" +
            "      pm.priority_nm, \n" +
            "      'PROJECT' AS task_source,\n" +
            "      ( \n" +
            "        SELECT jsonb_agg(jsonb_build_object( \n" +
            "          'empId', em.emp_id, \n" +
            "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), \n" +
            "          'photoUrl', em.photo_url, \n" +
            "          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END \n" +
            "        )) \n" +
            "        FROM employee_master em \n" +
            "        WHERE em.emp_id = t.emp_id \n" +
            "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.task_id = t.task_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true) \n" +
            "      ) AS employees \n" +
            "    FROM task_live_master t \n" +
            "    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id \n" +
            "    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id \n" +
            "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts \n" +
            "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority \n" +
            "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( \n" +
            "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true\n" +
            "    ) OR t.task_id IN (\n" +
            "      SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL\n" +
            "    )) \n" +
            "\n" +
            "    UNION ALL \n" +
            "\n" +
            "    SELECT \n" +
            "      t.emp_task_id AS task_id, \n" +
            "      t.task_cd,\n" +
            "      t.task_nm, \n" +
            "      t.st_dt, \n" +
            "      t.end_dt, \n" +
            "      (t.end_dt - t.st_dt) AS no_of_days, \n" +
            "      t.task_sts, \n" +
            "      tsm.status_nm, \n" +
            "      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS prj_cd, \n" +
            "      pm.priority_nm, \n" +
            "      'INDIVIDUAL' AS task_source,\n" +
            "      ( \n" +
            "        SELECT jsonb_agg(jsonb_build_object( \n" +
            "          'empId', em.emp_id, \n" +
            "          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), \n" +
            "          'photoUrl', em.photo_url, \n" +
            "          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END \n" +
            "        )) \n" +
            "        FROM employee_master em \n" +
            "        WHERE em.emp_id = t.emp_id \n" +
            "           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.emp_task_id = t.emp_task_id AND pc.emp_task_id IS NOT NULL) \n" +
            "      ) AS employees \n" +
            "    FROM employee_individual_task_master t \n" +
            "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts \n" +
            "    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority \n" +
            "    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( \n" +
            "      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL\n" +
            "    ) OR t.emp_task_id IN (\n" +
            "      SELECT tm.emp_task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.emp_task_id IS NOT NULL\n" +
            "    )) AND COALESCE(t.sts, true) = true \n" +
            "  ) \n" +
            "  SELECT jsonb_agg(sub) INTO v_upcoming \n" +
            "  FROM ( \n" +
            "    SELECT jsonb_build_object( \n" +
            "      'taskId', t.task_id, \n" +
            "      'taskCode', COALESCE(t.task_cd, CASE WHEN t.task_source = 'INDIVIDUAL' THEN 'IND-' || t.task_id ELSE 'TSK-' || t.task_id END),\n" +
            "      'taskNm', t.task_nm, \n" +
            "      'prjCd', t.prj_cd, \n" +
            "      'stDt', t.st_dt, \n" +
            "      'endDt', t.end_dt, \n" +
            "      'durationDays', t.no_of_days, \n" +
            "      'priority', CASE COALESCE(t.priority_nm, 'MEDIUM') \n" +
            "                    WHEN 'LOW' THEN 'Low' \n" +
            "                    WHEN 'NORMAL' THEN 'Medium' \n" +
            "                    WHEN 'MEDIUM' THEN 'Medium' \n" +
            "                    WHEN 'HIGH' THEN 'High' \n" +
            "                    WHEN 'CRITICAL' THEN 'High' \n" +
            "                    ELSE 'Medium' \n" +
            "                  END, \n" +
            "      'employees', COALESCE(t.employees, '[]'::jsonb) \n" +
            "    ) AS sub \n" +
            "    FROM all_upcoming t \n" +
            "    WHERE UPPER(t.status_nm) NOT IN ('COMPLETED', 'CLOSED') AND t.st_dt > v_today \n" +
            "    ORDER BY t.end_dt ASC NULLS LAST \n" +
            "    LIMIT 5 \n" +
            "  ) x; \n" +
            "\n" +
            "  /* 6. User Projects list with details and progress */ \n" +
            "  SELECT jsonb_agg(sub) INTO v_my_projects \n" +
            "  FROM ( \n" +
            "    SELECT jsonb_build_object( \n" +
            "      'projectId',     p.prj_id, \n" +
            "      'projectName',   p.prj_nm, \n" +
            "      'projectCode',   p.prj_cd, \n" +
            "      'clientName',    COALESCE(cm.coy_nm, (SELECT coy_nm FROM company_master LIMIT 1), ''), \n" +
            "      'plantName',     COALESCE(pm.plt_nm, (SELECT plt_nm FROM plant_master LIMIT 1), ''), \n" +
            "      'location',      COALESCE(cm.ct_vlg, (SELECT ct_vlg FROM company_master LIMIT 1), ''), \n" +
            "      'logo',          p.logo, \n" +
            "      'role',          COALESCE(pa.access_type, 'Team Member'), \n" +
            "      'status',        CASE \n" +
            "                         WHEN p.prj_sts = 'HOLD' THEN 'On Hold' \n" +
            "                         WHEN p.prj_sts = 'CLOSED' THEN 'Completed' \n" +
            "                         ELSE 'In Progress' \n" +
            "                       END, \n" +
            "      'dueDate',       p.end_dt, \n" +
            "      'tasksAssigned', COUNT(t.task_id), \n" +
            "      'openTasks',     COUNT(t.task_id) FILTER (WHERE UPPER(tsm.status_nm) NOT IN ('COMPLETED', 'CLOSED')), \n" +
            "      'closedTasks',   COUNT(t.task_id) FILTER (WHERE UPPER(tsm.status_nm) IN ('COMPLETED', 'CLOSED')),\n" +
            "      'progress',      COALESCE((\n" +
            "        SELECT ROUND(\n" +
            "          (SUM(\n" +
            "            CASE \n" +
            "              WHEN UPPER(tsm_all.status_nm) = 'COMPLETED' OR UPPER(tsm_all.status_nm) = 'CLOSED' THEN 1.0\n" +
            "              WHEN UPPER(tsm_all.status_nm) = 'WIP' OR UPPER(tsm_all.status_nm) = 'IN PROGRESS' THEN \n" +
            "                CASE \n" +
            "                  WHEN UPPER(t_all.sub_status) = 'UNDER REVIEW' THEN 0.8\n" +
            "                  WHEN UPPER(t_all.sub_status) = 'REWORK' THEN 0.2\n" +
            "                  ELSE 0.5\n" +
            "                END\n" +
            "              ELSE 0.0\n" +
            "            END\n" +
            "          ) / NULLIF(COUNT(t_all.task_id), 0)) * 100, 0)\n" +
            "        FROM task_live_master t_all\n" +
            "        JOIN milestone_live_master ml_all ON ml_all.m_id = t_all.m_id\n" +
            "        LEFT JOIN task_status_master tsm_all ON tsm_all.status_id = t_all.task_sts\n" +
            "        WHERE ml_all.prj_id = p.prj_id\n" +
            "          AND (t_all.emp_id = p_emp_id OR t_all.task_id IN (\n" +
            "            SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true\n" +
            "          ) OR t_all.task_id IN (\n" +
            "            SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL\n" +
            "          ))\n" +
            "          AND COALESCE(UPPER(tsm_all.status_nm), '') <> 'DRAFT'\n" +
            "      ), 0)\n" +
            "    ) AS sub \n" +
            "    FROM task_live_master t \n" +
            "    JOIN milestone_live_master  ml ON ml.m_id   = t.m_id \n" +
            "    JOIN project_live_master    p  ON p.prj_id  = ml.prj_id \n" +
            "    LEFT JOIN company_master    cm ON cm.coy_id = p.coy_id \n" +
            "    LEFT JOIN plant_master      pm ON pm.plt_id = p.plt_id \n" +
            "    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts \n" +
            "    LEFT JOIN project_access pa ON pa.prj_id = p.prj_id AND pa.emp_id = p_emp_id AND pa.sts = true \n" +
            "    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( \n" +
            "      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true \n" +
            "    ) OR t.task_id IN (\n" +
            "      SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL\n" +
            "    )) AND p.prj_sts IN ('LIVE', 'CLOSED', 'HOLD') \n" +
            "    GROUP BY p.prj_id, p.prj_nm, p.prj_cd, p.logo, cm.coy_nm, pm.plt_nm, cm.ct_vlg, p.prj_sts, pa.access_type, p.end_dt \n" +
            "    ORDER BY p.prj_nm \n" +
            "  ) x; \n" +
            "\n" +
            "  /* 8. Trend and Weekly Change Calculations */ \n" +
            "  DECLARE \n" +
            "    trend_rec RECORD; \n" +
            "  BEGIN \n" +
            "    WITH days AS ( \n" +
            "      SELECT (v_today - i * INTERVAL '1 day')::DATE AS d \n" +
            "      FROM generate_series(6, 0, -1) AS i \n" +
            "    ), \n" +
            "    trend_data AS ( \n" +
            "      SELECT \n" +
            "        d, \n" +
            "        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d) AS assigned_count, \n" +
            "        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d AND UPPER(status_nm) = 'OPEN' AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS open_count, \n" +
            "        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d AND (UPPER(status_nm) = 'WIP' OR UPPER(status_nm) = 'IN PROGRESS') AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS wip_count, \n" +
            "        (SELECT COUNT(*) FROM temp_all_tasks WHERE end_dt < d AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS overdue_count, \n" +
            "        (SELECT COUNT(*) FROM temp_all_tasks WHERE act_cmp_dt <= d) AS completed_count, \n" +
            "        (SELECT COUNT(DISTINCT m.prj_id) \n" +
            "         FROM task_live_master t_tr \n" +
            "         JOIN milestone_live_master m ON m.m_id = t_tr.m_id \n" +
            "         JOIN project_live_master p_tr ON p_tr.prj_id = m.prj_id \n" +
            "         WHERE (t_tr.emp_id = p_emp_id OR t_tr.task_id IN ( \n" +
            "           SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true \n" +
            "         ) OR t_tr.task_id IN (\n" +
            "           SELECT tm.task_id FROM team_members tm WHERE tm.emp_id = p_emp_id AND tm.task_id IS NOT NULL\n" +
            "         )) AND p_tr.prj_sts = 'LIVE' AND p_tr.st_dt <= d) AS projects_count \n" +
            "      FROM days \n" +
            "      ORDER BY d \n" +
            "    ) \n" +
            "    SELECT \n" +
            "      jsonb_object_agg(metric, jsonb_build_object( \n" +
            "        'trend', trend_array, \n" +
            "        'weeklyChange', GREATEST(0, current_val - seven_days_ago_val) \n" +
            "      )) \n" +
            "    INTO v_metrics_trends \n" +
            "    FROM ( \n" +
            "      SELECT \n" +
            "        'assignedTasks' AS metric, \n" +
            "        (SELECT jsonb_agg(assigned_count) FROM trend_data) AS trend_array, \n" +
            "        (SELECT assigned_count FROM trend_data WHERE d = v_today) AS current_val, \n" +
            "        COALESCE((SELECT assigned_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val \n" +
            "      UNION ALL \n" +
            "      SELECT \n" +
            "        'openTasks' AS metric, \n" +
            "        (SELECT jsonb_agg(open_count) FROM trend_data) AS trend_array, \n" +
            "        (SELECT open_count FROM trend_data WHERE d = v_today) AS current_val, \n" +
            "        COALESCE((SELECT open_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val \n" +
            "      UNION ALL \n" +
            "      SELECT \n" +
            "        'inProgress' AS metric, \n" +
            "        (SELECT jsonb_agg(wip_count) FROM trend_data) AS trend_array, \n" +
            "        (SELECT wip_count FROM trend_data WHERE d = v_today) AS current_val, \n" +
            "        COALESCE((SELECT wip_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val \n" +
            "      UNION ALL \n" +
            "      SELECT \n" +
            "        'overdueTasks' AS metric, \n" +
            "        (SELECT jsonb_agg(overdue_count) FROM trend_data) AS trend_array, \n" +
            "        (SELECT overdue_count FROM trend_data WHERE d = v_today) AS current_val, \n" +
            "        COALESCE((SELECT overdue_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val \n" +
            "      UNION ALL \n" +
            "      SELECT \n" +
            "        'closedTasks' AS metric, \n" +
            "        (SELECT jsonb_agg(completed_count) FROM trend_data) AS trend_array, \n" +
            "        (SELECT completed_count FROM trend_data WHERE d = v_today) AS current_val, \n" +
            "        COALESCE((SELECT completed_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val \n" +
            "      UNION ALL \n" +
            "      SELECT \n" +
            "        'completedTasks' AS metric, \n" +
            "        (SELECT jsonb_agg(completed_count) FROM trend_data) AS trend_array, \n" +
            "        (SELECT completed_count FROM trend_data WHERE d = v_today) AS current_val, \n" +
            "        COALESCE((SELECT completed_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val \n" +
            "      UNION ALL \n" +
            "      SELECT \n" +
            "        'myProjects' AS metric, \n" +
            "        (SELECT jsonb_agg(projects_count) FROM trend_data) AS trend_array, \n" +
            "        (SELECT projects_count FROM trend_data WHERE d = v_today) AS current_val, \n" +
            "        COALESCE((SELECT projects_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val \n" +
            "    ) x; \n" +
            "  END; \n" +
            "\n" +
            "  /* 9. Recent Activity List */ \n" +
            "  SELECT jsonb_agg(sub) INTO v_recent_activity \n" +
            "  FROM ( \n" +
            "    SELECT jsonb_build_object( \n" +
            "      'logId',      al.log_id, \n" +
            "      'entityTyp',  al.entity_typ, \n" +
            "      'entityId',   al.entity_id, \n" +
            "      'statusFrom', al.status_from, \n" +
            "      'statusTo',   al.status_to, \n" +
            "      'logDt',      al.log_dt, \n" +
            "      'message',    CASE \n" +
            "                      WHEN al.entity_typ = 'TASK' THEN \n" +
            "                        'Task \"' || COALESCE(t.task_nm, 'Unknown Task') || '\" updated from ' || al.status_from || ' to ' || al.status_to \n" +
            "                      WHEN al.entity_typ = 'MILESTONE' THEN \n" +
            "                        'Milestone \"' || COALESCE(m.mlstn_ttl, 'Unknown Milestone') || '\" updated from ' || al.status_from || ' to ' || al.status_to \n" +
            "                      WHEN al.entity_typ = 'PROJECT' THEN \n" +
            "                        'Project \"' || COALESCE(p.prj_nm, 'Unknown Project') || '\" updated from ' || al.status_from || ' to ' || al.status_to \n" +
            "                      ELSE 'Activity log updated' \n" +
            "                    END, \n" +
            "      'projectName', COALESCE(p.prj_nm, p_ind.prj_nm, 'Internal') \n" +
            "    ) AS sub \n" +
            "    FROM activity_log_transaction al \n" +
            "    LEFT JOIN task_live_master t ON al.entity_typ = 'TASK' AND t.task_id = al.entity_id \n" +
            "    LEFT JOIN milestone_live_master m ON \n" +
            "      (al.entity_typ = 'MILESTONE' AND m.m_id = al.entity_id) OR \n" +
            "      (al.entity_typ = 'TASK' AND m.m_id = t.m_id) \n" +
            "    LEFT JOIN project_live_master p ON \n" +
            "      (al.entity_typ = 'PROJECT' AND p.prj_id = al.entity_id) OR \n" +
            "      (m.prj_id = p.prj_id) \n" +
            "    LEFT JOIN employee_individual_task_master ind ON al.entity_typ = 'TASK' AND ind.emp_task_id = al.entity_id \n" +
            "    LEFT JOIN (SELECT DISTINCT prj_cd, prj_nm FROM project_live_master) p_ind ON p_ind.prj_cd = ind.task_asgn_to \n" +
            "    WHERE \n" +
            "      (al.entity_typ = 'TASK' AND (t.emp_id = p_emp_id OR ind.emp_id = p_emp_id OR t.task_id IN ( \n" +
            "         SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true \n" +
            "      ) OR ind.emp_task_id IN ( \n" +
            "         SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL \n" +
            "      ))) \n" +
            "      OR (p.prj_id IN ( \n" +
            "         SELECT DISTINCT ml_sub.prj_id \n" +
            "         FROM task_live_master t_sub \n" +
            "         JOIN milestone_live_master ml_sub ON ml_sub.m_id = t_sub.m_id \n" +
            "         WHERE t_sub.emp_id = p_emp_id OR t_sub.task_id IN ( \n" +
            "           SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.task_id IS NOT NULL AND COALESCE(pc.is_live, true) = true \n" +
            "         ) \n" +
            "      )) \n" +
            "    ORDER BY al.log_dt DESC \n" +
            "    LIMIT 5 \n" +
            "  ) x; \n" +
            "\n" +
            "  /* 10. Performance Calculations */ \n" +
            "  SELECT COALESCE( \n" +
            "    ROUND( \n" +
            "      (COUNT(*) FILTER (WHERE UPPER(status_nm) IN ('CLOSED', 'COMPLETED') AND (act_cmp_dt IS NULL OR act_cmp_dt <= end_dt))::NUMERIC / \n" +
            "       NULLIF(COUNT(*) FILTER (WHERE UPPER(status_nm) IN ('CLOSED', 'COMPLETED')), 0)) * 100, \n" +
            "      0 \n" +
            "    )::INT, \n" +
            "    100 \n" +
            "  ) INTO v_productivity \n" +
            "  FROM temp_all_tasks; \n" +
            "\n" +
            "  v_quality := GREATEST(50, 100 - ((v_reassigned + v_rework) * 5)); \n" +
            "\n" +
            "  v_performance := jsonb_build_object( \n" +
            "    'productivity', jsonb_build_object( \n" +
            "      'score', v_productivity, \n" +
            "      'rating', CASE \n" +
            "                  WHEN v_productivity >= 90 THEN 'Excellent' \n" +
            "                  WHEN v_productivity >= 75 THEN 'Good' \n" +
            "                  WHEN v_productivity >= 50 THEN 'Satisfactory' \n" +
            "                  ELSE 'Needs Improvement' \n" +
            "                END \n" +
            "    ), \n" +
            "    'taskCompletion', jsonb_build_object( \n" +
            "      'score', CASE WHEN v_total_tasks > 0 THEN ROUND((v_completed::NUMERIC/v_total_tasks)*100,0)::INT ELSE 100 END, \n" +
            "      'rating', CASE \n" +
            "                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 90 THEN 'Excellent' \n" +
            "                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 75 THEN 'Good' \n" +
            "                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 50 THEN 'Satisfactory' \n" +
            "                  ELSE 'Needs Improvement' \n" +
            "                END \n" +
            "    ), \n" +
            "    'qualityScore', jsonb_build_object( \n" +
            "      'score', v_quality, \n" +
            "      'rating', CASE \n" +
            "                  WHEN v_quality >= 90 THEN 'Excellent' \n" +
            "                  WHEN v_quality >= 75 THEN 'Good' \n" +
            "                  WHEN v_quality >= 50 THEN 'Satisfactory' \n" +
            "                  ELSE 'Needs Improvement' \n" +
            "                END \n" +
            "    ) \n" +
            "  ); \n" +
            "\n" +
            "  /* 7. Combined response return */ \n" +
            "  RETURN jsonb_build_object( \n" +
            "    'profile', jsonb_build_object( \n" +
            "      'empId', p_emp_id, 'fullName', v_full_name, \n" +
            "      'role', COALESCE(v_emp.desig_nm, 'Site Engineer'), \n" +
            "      'department', COALESCE(v_emp.dept_nm, 'Projects Department'), \n" +
            "      'photoUrl', v_emp.photo_url), \n" +
            "    'summary', jsonb_build_object( \n" +
            "      'totalTasks', v_total_tasks,\n" +
            "      'myTasksCount', v_total_tasks, \n" +
            "      'closedTasksCount', v_completed,\n" +
            "      'closedCount', v_completed,\n" +
            "      'completedTasksCount', v_completed,\n" +
            "      'overdueTasksCount', v_overdue, \n" +
            "      'dueTodayCount', v_due_today, \n" +
            "      'myProjectsCount', v_my_prj_count, \n" +
            "      'overallCompletion', CASE WHEN v_total_tasks > 0 \n" +
            "        THEN ROUND((v_completed::NUMERIC/v_total_tasks)*100,2) ELSE 0 END), \n" +
            "    'taskStatusCounts', jsonb_build_object( \n" +
            "      'Closed', v_completed, 'In Progress', v_wip, \n" +
            "      'Under Review', v_under_review, 'Overdue', v_overdue, \n" +
            "      'Open', v_open, 'Reassigned', v_reassigned, \n" +
            "      'Rework', v_rework, 'Draft', v_draft), \n" +
            "    'todoList',      COALESCE(v_todo_list, '[]'::jsonb), \n" +
            "    'upcomingTasks', COALESCE(v_upcoming, '[]'::jsonb), \n" +
            "    'myProjects',    COALESCE(v_my_projects, '[]'::jsonb), \n" +
            "    'metricsTrends', COALESCE(v_metrics_trends, '{}'::jsonb), \n" +
            "    'recentActivity', COALESCE(v_recent_activity, '[]'::jsonb), \n" +
            "    'performance',   v_performance \n" +
            "  ); \n" +
            "END; \n" +
            "$function$;";

        try (FileWriter fw = new FileWriter("sql_check.sql")) {
            fw.write(sql);
        }
        System.out.println("SQL written to sql_check.sql successfully.");
    }
}
