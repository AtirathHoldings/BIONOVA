CREATE OR REPLACE FUNCTION get_user_dashboard(p_emp_id BIGINT) 
RETURNS jsonb 
LANGUAGE plpgsql 
SECURITY DEFINER 
AS $$ 
DECLARE 
  v_today          DATE := CURRENT_DATE; 
  v_emp            RECORD; 
  v_full_name      TEXT; 
  v_total_tasks    INT := 0; 
  v_completed      INT := 0; 
  v_overdue        INT := 0; 
  v_due_today      INT := 0; 
  v_wip            INT := 0; 
  v_under_review   INT := 0; 
  v_open           INT := 0; 
  v_reassigned     INT := 0; 
  v_rework         INT := 0; 
  v_draft          INT := 0; 
  v_my_prj_count   BIGINT := 0; 
  v_todo_list      jsonb; 
  v_upcoming       jsonb; 
  v_my_projects    jsonb; 
  v_metrics_trends jsonb; 
  v_recent_activity jsonb; 
  v_performance    jsonb; 
  v_productivity   INT := 100; 
  v_quality        INT := 100; 
BEGIN 
  /* 1. Employee Profile Details */ 
  SELECT em.emp_id, em.fst_nm, em.lst_nm, em.photo_url, 
         dm.desig_nm, dept.dept_nm 
  INTO v_emp 
  FROM employee_master em 
  LEFT JOIN designation_master dm   ON dm.desig_id = em.desig_id 
  LEFT JOIN department_master  dept ON dept.dept_id = em.dept_id 
  WHERE em.emp_id = p_emp_id; 

  v_full_name := TRIM(COALESCE(v_emp.fst_nm,'')||' '||COALESCE(v_emp.lst_nm,'')); 

  /* 2. Task Counts from BOTH project tasks and individual assignments using Temporary Table */ 
  DROP TABLE IF EXISTS temp_all_tasks; 
  CREATE TEMPORARY TABLE temp_all_tasks ON COMMIT DROP AS 
    SELECT 
      t.task_id, 
      t.task_nm, 
      t.st_dt, 
      t.end_dt, 
      t.act_cmp_dt, 
      t.no_of_days, 
      t.task_sts, 
      tsm.status_nm, 
      COALESCE(p.prj_cd || ' - ' || m.mlstn_ttl, '') AS project_info, 
      COALESCE(p.prj_cd, '') AS prj_cd, 
      CASE 
        WHEN t.emp_id = p_emp_id THEN 'Executor' 
        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 1) THEN 'Reviewer' 
        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 2) THEN 'Approver' 
        ELSE 'Executor' 
      END AS user_badge, 
      pm.priority_nm, 
      'PROJECT' AS task_source 
    FROM task_live_master t 
    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id 
    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id 
    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority 
    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( 
      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true 
    )) 

    UNION ALL 

    SELECT 
      t.emp_task_id AS task_id, 
      t.task_nm, 
      t.st_dt, 
      t.end_dt, 
      CASE WHEN tsm.status_nm = 'COMPLETED' THEN t.end_dt ELSE NULL END AS act_cmp_dt, 
      (t.end_dt - t.st_dt) AS no_of_days, 
      t.task_sts, 
      tsm.status_nm, 
      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS project_info, 
      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS prj_cd, 
      CASE 
        WHEN t.emp_id = p_emp_id THEN 'Executor' 
        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 1) THEN 'Reviewer' 
        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 2) THEN 'Approver' 
        ELSE 'Executor' 
      END AS user_badge, 
      pm.priority_nm, 
      'INDIVIDUAL' AS task_source 
    FROM employee_individual_task_master t 
    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority 
    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( 
      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL 
    )) AND COALESCE(t.sts, true) = true 
  ; 

  SELECT 
    COUNT(*), 
    COUNT(*) FILTER (WHERE status_nm = 'COMPLETED'), 
    COUNT(*) FILTER (WHERE status_nm = 'OVER_DUE' OR (status_nm <> 'COMPLETED' AND end_dt IS NOT NULL AND end_dt < v_today)), 
    COUNT(*) FILTER (WHERE status_nm <> 'COMPLETED' AND end_dt = v_today), 
    COUNT(*) FILTER (WHERE status_nm = 'WIP'), 
    COUNT(*) FILTER (WHERE status_nm = 'UNDER_REVIEW'), 
    COUNT(*) FILTER (WHERE status_nm = 'OPEN'), 
    COUNT(*) FILTER (WHERE status_nm = 'REASSIGN'), 
    COUNT(*) FILTER (WHERE status_nm = 'REWORK'), 
    COUNT(*) FILTER (WHERE status_nm = 'DRAFT') 
  INTO v_total_tasks, v_completed, v_overdue, v_due_today, 
       v_wip, v_under_review, v_open, v_reassigned, v_rework, v_draft 
  FROM temp_all_tasks; 

  /* 3. Projects Count (Only active projects) */ 
  SELECT COUNT(DISTINCT m.prj_id) INTO v_my_prj_count 
  FROM task_live_master t 
  JOIN milestone_live_master m ON m.m_id = t.m_id 
  JOIN project_live_master p ON p.prj_id = m.prj_id 
  WHERE (t.emp_id = p_emp_id OR t.task_id IN ( 
    SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true 
  )) AND p.prj_sts = 'LIVE'; 

  /* 4. To-Do List (Limit 5, ordered by end_dt) */ 
  WITH all_todo AS ( 
    SELECT 
      t.task_id, 
      t.task_nm, 
      t.st_dt, 
      t.end_dt, 
      t.task_sts, 
      tsm.status_nm, 
      COALESCE(p.prj_cd || ' - ' || m.mlstn_ttl, '') AS project_info, 
      CASE 
        WHEN t.emp_id = p_emp_id THEN 'Executor' 
        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 1) THEN 'Reviewer' 
        WHEN t.task_id IN (SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true AND pc.ordr_id = 2) THEN 'Approver' 
        ELSE 'Executor' 
      END AS user_badge, 
      pm.priority_nm, 
      ( 
        SELECT jsonb_agg(jsonb_build_object( 
          'empId', em.emp_id, 
          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), 
          'photoUrl', em.photo_url, 
          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END 
        )) 
        FROM employee_master em 
        WHERE em.emp_id = t.emp_id 
           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.task_id = t.task_id AND pc.is_live = true) 
      ) AS employees 
    FROM task_live_master t 
    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id 
    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id 
    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority 
    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( 
      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true 
    )) 

    UNION ALL 

    SELECT 
      t.emp_task_id AS task_id, 
      t.task_nm, 
      t.st_dt, 
      t.end_dt, 
      t.task_sts, 
      tsm.status_nm, 
      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS project_info, 
      CASE 
        WHEN t.emp_id = p_emp_id THEN 'Executor' 
        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 1) THEN 'Reviewer' 
        WHEN t.emp_task_id IN (SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL AND pc.ordr_id = 2) THEN 'Approver' 
        ELSE 'Executor' 
      END AS user_badge, 
      pm.priority_nm, 
      ( 
        SELECT jsonb_agg(jsonb_build_object( 
          'empId', em.emp_id, 
          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), 
          'photoUrl', em.photo_url, 
          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END 
        )) 
        FROM employee_master em 
        WHERE em.emp_id = t.emp_id 
           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.emp_task_id = t.emp_task_id AND pc.emp_task_id IS NOT NULL) 
      ) AS employees 
    FROM employee_individual_task_master t 
    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority 
    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( 
      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL 
    )) AND COALESCE(t.sts, true) = true 
  ) 
  SELECT jsonb_agg(sub) INTO v_todo_list 
  FROM ( 
    SELECT jsonb_build_object( 
      'taskId', t.task_id, 
      'taskNm', t.task_nm, 
      'project', t.project_info, 
      'endDt', t.end_dt, 
      'status', t.status_nm, 
      'isOverdue', (t.status_nm = 'OVER_DUE' OR (t.status_nm <> 'COMPLETED' AND t.end_dt < v_today)), 
      'isDueToday', (t.status_nm <> 'COMPLETED' AND t.end_dt = v_today), 
      'priority', CASE COALESCE(t.priority_nm, 'MEDIUM') 
                    WHEN 'LOW' THEN 'Low' 
                    WHEN 'NORMAL' THEN 'Medium' 
                    WHEN 'MEDIUM' THEN 'Medium' 
                    WHEN 'HIGH' THEN 'High' 
                    WHEN 'CRITICAL' THEN 'High' 
                    ELSE 'Medium' 
                  END, 
      'badge', t.user_badge, 
      'employees', COALESCE(t.employees, '[]'::jsonb) 
    ) AS sub 
    FROM all_todo t 
    WHERE t.status_nm <> 'COMPLETED' AND t.st_dt <= v_today 
    ORDER BY t.end_dt ASC NULLS LAST 
    LIMIT 5 
  ) x; 

  /* 5. Upcoming Tasks (Limit 5, ordered by end_dt) */ 
  WITH all_upcoming AS ( 
    SELECT 
      t.task_id, 
      t.task_nm, 
      t.st_dt, 
      t.end_dt, 
      t.no_of_days, 
      t.task_sts, 
      tsm.status_nm, 
      COALESCE(p.prj_cd, '') AS prj_cd, 
      pm.priority_nm, 
      ( 
        SELECT jsonb_agg(jsonb_build_object( 
          'empId', em.emp_id, 
          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), 
          'photoUrl', em.photo_url, 
          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END 
        )) 
        FROM employee_master em 
        WHERE em.emp_id = t.emp_id 
           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.task_id = t.task_id AND pc.is_live = true) 
      ) AS employees 
    FROM task_live_master t 
    LEFT JOIN milestone_live_master m ON m.m_id = t.m_id 
    LEFT JOIN project_live_master p ON p.prj_id = m.prj_id 
    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority 
    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( 
      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true 
    )) 

    UNION ALL 

    SELECT 
      t.emp_task_id AS task_id, 
      t.task_nm, 
      t.st_dt, 
      t.end_dt, 
      (t.end_dt - t.st_dt) AS no_of_days, 
      t.task_sts, 
      tsm.status_nm, 
      COALESCE(INITCAP(t.task_asgn_to), 'Internal') AS prj_cd, 
      pm.priority_nm, 
      ( 
        SELECT jsonb_agg(jsonb_build_object( 
          'empId', em.emp_id, 
          'fullName', TRIM(COALESCE(em.fst_nm,'')||' '||COALESCE(em.lst_nm,'')), 
          'photoUrl', em.photo_url, 
          'role', CASE WHEN t.emp_id = em.emp_id THEN 'Executor' ELSE 'Reviewer/Approver' END 
        )) 
        FROM employee_master em 
        WHERE em.emp_id = t.emp_id 
           OR em.emp_id IN (SELECT pc.emp_id FROM process_config pc WHERE pc.emp_task_id = t.emp_task_id AND pc.emp_task_id IS NOT NULL) 
      ) AS employees 
    FROM employee_individual_task_master t 
    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
    LEFT JOIN task_priority_master pm ON pm.priority_id = t.priority 
    WHERE (t.emp_id = p_emp_id OR t.emp_task_id IN ( 
      SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL 
    )) AND COALESCE(t.sts, true) = true 
  ) 
  SELECT jsonb_agg(sub) INTO v_upcoming 
  FROM ( 
    SELECT jsonb_build_object( 
      'taskId', t.task_id, 
      'taskNm', t.task_nm, 
      'prjCd', t.prj_cd, 
      'stDt', t.st_dt, 
      'endDt', t.end_dt, 
      'durationDays', t.no_of_days, 
      'priority', CASE COALESCE(t.priority_nm, 'MEDIUM') 
                    WHEN 'LOW' THEN 'Low' 
                    WHEN 'NORMAL' THEN 'Medium' 
                    WHEN 'MEDIUM' THEN 'Medium' 
                    WHEN 'HIGH' THEN 'High' 
                    WHEN 'CRITICAL' THEN 'High' 
                    ELSE 'Medium' 
                  END, 
      'employees', COALESCE(t.employees, '[]'::jsonb) 
    ) AS sub 
    FROM all_upcoming t 
    WHERE t.status_nm <> 'COMPLETED' AND t.st_dt > v_today 
    ORDER BY t.end_dt ASC NULLS LAST 
    LIMIT 5 
  ) x; 

  /* 6. User Projects list with details and progress */ 
  SELECT jsonb_agg(sub) INTO v_my_projects 
  FROM ( 
    SELECT jsonb_build_object( 
      'projectId',     p.prj_id, 
      'projectName',   p.prj_nm, 
      'projectCode',   p.prj_cd, 
      'clientName',    COALESCE(cm.coy_nm, (SELECT coy_nm FROM company_master LIMIT 1), ''), 
      'plantName',     COALESCE(pm.plt_nm, (SELECT plt_nm FROM plant_master LIMIT 1), ''), 
      'location',      COALESCE(cm.ct_vlg, (SELECT ct_vlg FROM company_master LIMIT 1), ''), 
      'logo',          p.logo, 
      'role',          COALESCE(pa.access_type, 'Team Member'), 
      'status',        CASE 
                         WHEN p.prj_sts = 'HOLD' THEN 'On Hold' 
                         WHEN p.prj_sts = 'CLOSED' THEN 'Completed' 
                         ELSE 'In Progress' 
                       END, 
      'dueDate',       p.end_dt, 
      'tasksAssigned', COUNT(t.task_id), 
      'openTasks',     COUNT(t.task_id) FILTER (WHERE tsm.status_nm <> 'COMPLETED'), 
      'progress',      ROUND( 
        CASE WHEN COUNT(t.task_id) > 0 
          THEN (COUNT(t.task_id) FILTER (WHERE tsm.status_nm = 'COMPLETED')::NUMERIC / COUNT(t.task_id)) * 100 
          ELSE 0 END, 0) 
    ) AS sub 
    FROM task_live_master t 
    JOIN milestone_live_master  ml ON ml.m_id   = t.m_id 
    JOIN project_live_master    p  ON p.prj_id  = ml.prj_id 
    LEFT JOIN company_master    cm ON cm.coy_id = p.coy_id 
    LEFT JOIN plant_master      pm ON pm.plt_id = p.plt_id 
    LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
    LEFT JOIN project_access pa ON pa.prj_id = p.prj_id AND pa.emp_id = p_emp_id AND pa.sts = true 
    WHERE (t.emp_id = p_emp_id OR t.task_id IN ( 
      SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true 
    )) AND p.prj_sts IN ('LIVE', 'CLOSED', 'HOLD') 
    GROUP BY p.prj_id, p.prj_nm, p.prj_cd, p.logo, cm.coy_nm, pm.plt_nm, cm.ct_vlg, p.prj_sts, pa.access_type, p.end_dt 
    ORDER BY p.prj_nm 
  ) x; 

  /* 8. Trend and Weekly Change Calculations */ 
  DECLARE 
    trend_rec RECORD; 
  BEGIN 
    WITH days AS ( 
      SELECT (v_today - i * INTERVAL '1 day')::DATE AS d 
      FROM generate_series(6, 0, -1) AS i 
    ), 
    trend_data AS ( 
      SELECT 
        d, 
        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d) AS assigned_count, 
        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d AND status_nm = 'OPEN' AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS open_count, 
        (SELECT COUNT(*) FROM temp_all_tasks WHERE st_dt <= d AND status_nm = 'WIP' AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS wip_count, 
        (SELECT COUNT(*) FROM temp_all_tasks WHERE end_dt < d AND (act_cmp_dt IS NULL OR act_cmp_dt > d)) AS overdue_count, 
        (SELECT COUNT(*) FROM temp_all_tasks WHERE act_cmp_dt <= d) AS completed_count, 
        (SELECT COUNT(DISTINCT m.prj_id) 
         FROM task_live_master t_tr 
         JOIN milestone_live_master m ON m.m_id = t_tr.m_id 
         JOIN project_live_master p_tr ON p_tr.prj_id = m.prj_id 
         WHERE (t_tr.emp_id = p_emp_id OR t_tr.task_id IN ( 
           SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true 
         )) AND p_tr.prj_sts = 'LIVE' AND p_tr.st_dt <= d) AS projects_count 
      FROM days 
      ORDER BY d 
    ) 
    SELECT 
      jsonb_object_agg(metric, jsonb_build_object( 
        'trend', trend_array, 
        'weeklyChange', GREATEST(0, current_val - seven_days_ago_val) 
      )) 
    INTO v_metrics_trends 
    FROM ( 
      SELECT 
        'assignedTasks' AS metric, 
        (SELECT jsonb_agg(assigned_count) FROM trend_data) AS trend_array, 
        (SELECT assigned_count FROM trend_data WHERE d = v_today) AS current_val, 
        COALESCE((SELECT assigned_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val 
      UNION ALL 
      SELECT 
        'openTasks' AS metric, 
        (SELECT jsonb_agg(open_count) FROM trend_data) AS trend_array, 
        (SELECT open_count FROM trend_data WHERE d = v_today) AS current_val, 
        COALESCE((SELECT open_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val 
      UNION ALL 
      SELECT 
        'inProgress' AS metric, 
        (SELECT jsonb_agg(wip_count) FROM trend_data) AS trend_array, 
        (SELECT wip_count FROM trend_data WHERE d = v_today) AS current_val, 
        COALESCE((SELECT wip_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val 
      UNION ALL 
      SELECT 
        'overdueTasks' AS metric, 
        (SELECT jsonb_agg(overdue_count) FROM trend_data) AS trend_array, 
        (SELECT overdue_count FROM trend_data WHERE d = v_today) AS current_val, 
        COALESCE((SELECT overdue_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val 
      UNION ALL 
      SELECT 
        'completedTasks' AS metric, 
        (SELECT jsonb_agg(completed_count) FROM trend_data) AS trend_array, 
        (SELECT completed_count FROM trend_data WHERE d = v_today) AS current_val, 
        COALESCE((SELECT completed_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val 
      UNION ALL 
      SELECT 
        'myProjects' AS metric, 
        (SELECT jsonb_agg(projects_count) FROM trend_data) AS trend_array, 
        (SELECT projects_count FROM trend_data WHERE d = v_today) AS current_val, 
        COALESCE((SELECT projects_count FROM trend_data LIMIT 1), 0) AS seven_days_ago_val 
    ) x; 
  END; 

  /* 9. Recent Activity List */ 
  SELECT jsonb_agg(sub) INTO v_recent_activity 
  FROM ( 
    SELECT jsonb_build_object( 
      'logId',      al.log_id, 
      'entityTyp',  al.entity_typ, 
      'entityId',   al.entity_id, 
      'statusFrom', al.status_from, 
      'statusTo',   al.status_to, 
      'logDt',      al.log_dt, 
      'message',    CASE 
                      WHEN al.entity_typ = 'TASK' THEN 
                        'Task "' || COALESCE(t.task_nm, 'Unknown Task') || '" updated from ' || al.status_from || ' to ' || al.status_to 
                      WHEN al.entity_typ = 'MILESTONE' THEN 
                        'Milestone "' || COALESCE(m.mlstn_ttl, 'Unknown Milestone') || '" updated from ' || al.status_from || ' to ' || al.status_to 
                      WHEN al.entity_typ = 'PROJECT' THEN 
                        'Project "' || COALESCE(p.prj_nm, 'Unknown Project') || '" updated from ' || al.status_from || ' to ' || al.status_to 
                      ELSE 'Activity log updated' 
                    END, 
      'projectName', COALESCE(p.prj_nm, p_ind.prj_nm, 'Internal') 
    ) AS sub 
    FROM activity_log_transaction al 
    LEFT JOIN task_live_master t ON al.entity_typ = 'TASK' AND t.task_id = al.entity_id 
    LEFT JOIN milestone_live_master m ON 
      (al.entity_typ = 'MILESTONE' AND m.m_id = al.entity_id) OR 
      (al.entity_typ = 'TASK' AND m.m_id = t.m_id) 
    LEFT JOIN project_live_master p ON 
      (al.entity_typ = 'PROJECT' AND p.prj_id = al.entity_id) OR 
      (m.prj_id = p.prj_id) 
    LEFT JOIN employee_individual_task_master ind ON al.entity_typ = 'TASK' AND ind.emp_task_id = al.entity_id 
    LEFT JOIN (SELECT DISTINCT prj_cd, prj_nm FROM project_live_master) p_ind ON p_ind.prj_cd = ind.task_asgn_to 
    WHERE 
      (al.entity_typ = 'TASK' AND (t.emp_id = p_emp_id OR ind.emp_id = p_emp_id OR t.task_id IN ( 
         SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true 
      ) OR ind.emp_task_id IN ( 
         SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.emp_task_id IS NOT NULL 
      ))) 
      OR (p.prj_id IN ( 
         SELECT DISTINCT ml_sub.prj_id 
         FROM task_live_master t_sub 
         JOIN milestone_live_master ml_sub ON ml_sub.m_id = t_sub.m_id 
         WHERE t_sub.emp_id = p_emp_id OR t_sub.task_id IN ( 
           SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = p_emp_id AND pc.is_live = true 
         ) 
      )) 
    ORDER BY al.log_dt DESC 
    LIMIT 5 
  ) x; 

  /* 10. Performance Calculations */ 
  SELECT COALESCE( 
    ROUND( 
      (COUNT(*) FILTER (WHERE status_nm = 'COMPLETED' AND (act_cmp_dt IS NULL OR act_cmp_dt <= end_dt))::NUMERIC / 
       NULLIF(COUNT(*) FILTER (WHERE status_nm = 'COMPLETED'), 0)) * 100, 
      0 
    )::INT, 
    100 
  ) INTO v_productivity 
  FROM temp_all_tasks; 

  v_quality := GREATEST(50, 100 - ((v_reassigned + v_rework) * 5)); 

  v_performance := jsonb_build_object( 
    'productivity', jsonb_build_object( 
      'score', v_productivity, 
      'rating', CASE 
                  WHEN v_productivity >= 90 THEN 'Excellent' 
                  WHEN v_productivity >= 75 THEN 'Good' 
                  WHEN v_productivity >= 50 THEN 'Satisfactory' 
                  ELSE 'Needs Improvement' 
                END 
    ), 
    'taskCompletion', jsonb_build_object( 
      'score', CASE WHEN v_total_tasks > 0 THEN ROUND((v_completed::NUMERIC/v_total_tasks)*100,0)::INT ELSE 100 END, 
      'rating', CASE 
                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 90 THEN 'Excellent' 
                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 75 THEN 'Good' 
                  WHEN (CASE WHEN v_total_tasks > 0 THEN (v_completed::NUMERIC/v_total_tasks)*100 ELSE 100 END) >= 50 THEN 'Satisfactory' 
                  ELSE 'Needs Improvement' 
                END 
    ), 
    'qualityScore', jsonb_build_object( 
      'score', v_quality, 
      'rating', CASE 
                  WHEN v_quality >= 90 THEN 'Excellent' 
                  WHEN v_quality >= 75 THEN 'Good' 
                  WHEN v_quality >= 50 THEN 'Satisfactory' 
                  ELSE 'Needs Improvement' 
                END 
    ) 
  ); 

  /* 7. Combined response return */ 
  RETURN jsonb_build_object( 
    'profile', jsonb_build_object( 
      'empId', p_emp_id, 'fullName', v_full_name, 
      'role', COALESCE(v_emp.desig_nm, 'Site Engineer'), 
      'department', COALESCE(v_emp.dept_nm, 'Projects Department'), 
      'photoUrl', v_emp.photo_url), 
    'summary', jsonb_build_object( 
      'myTasksCount', (v_total_tasks - v_completed - v_overdue), 
      'completedTasksCount', v_completed, 
      'overdueTasksCount', v_overdue, 
      'dueTodayCount', v_due_today, 
      'myProjectsCount', v_my_prj_count, 
      'overallCompletion', CASE WHEN v_total_tasks > 0 
        THEN ROUND((v_completed::NUMERIC/v_total_tasks)*100,2) ELSE 0 END), 
    'taskStatusCounts', jsonb_build_object( 
      'Completed', v_completed, 'In Progress', v_wip, 
      'Under Review', v_under_review, 'Overdue', v_overdue, 
      'Open', v_open, 'Reassigned', v_reassigned, 
      'Rework', v_rework, 'Draft', v_draft), 
    'todoList',      COALESCE(v_todo_list, '[]'::jsonb), 
    'upcomingTasks', COALESCE(v_upcoming, '[]'::jsonb), 
    'myProjects',    COALESCE(v_my_projects, '[]'::jsonb), 
    'metricsTrends', COALESCE(v_metrics_trends, '{}'::jsonb), 
    'recentActivity', COALESCE(v_recent_activity, '[]'::jsonb), 
    'performance',   v_performance 
  ); 
END; 
$$;