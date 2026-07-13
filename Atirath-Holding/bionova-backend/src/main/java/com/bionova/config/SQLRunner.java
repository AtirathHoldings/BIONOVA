package com.bionova.config;

public class SQLRunner {
    
    private static final String HEADER = 
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
            "BEGIN ";

    private static final String FOOTER = 
            "  -- 7. Combined response return " +
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
            "    'myProjects',    COALESCE(v_my_projects, '[]'::jsonb) " +
            "  ); " +
            "END; " +
            "$$;";

    private static final String SELECT_INTO = 
            "  SELECT em.emp_id, em.fst_nm, em.lst_nm, em.photo_url, " +
            "         dm.desig_nm, dept.dept_nm " +
            "  INTO v_emp " +
            "  FROM employee_master em " +
            "  LEFT JOIN designation_master dm   ON dm.desig_id = em.desig_id " +
            "  LEFT JOIN department_master  dept ON dept.dept_id = em.dept_id " +
            "  WHERE em.emp_id = p_emp_id; ";

    private static final String ASSIGNMENT = 
            "  v_full_name := TRIM(COALESCE(v_emp.fst_nm,'')||' '||COALESCE(v_emp.lst_nm,'')); ";

    public static void main(String[] args) throws Exception {
        String f3_all = "  RETURN jsonb_build_object( " +
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
                "    'myProjects',    COALESCE(v_my_projects, '[]'::jsonb) " +
                "  ); END; $$;";

        String sqlFailed = HEADER + SELECT_INTO + ASSIGNMENT + FOOTER;
        String sqlSucceeded = HEADER + SELECT_INTO + ASSIGNMENT + f3_all;

        System.out.println("Length Failed: " + sqlFailed.length());
        System.out.println("Length Succeeded: " + sqlSucceeded.length());

        int minLen = Math.min(sqlFailed.length(), sqlSucceeded.length());
        for (int i = 0; i < minLen; i++) {
            if (sqlFailed.charAt(i) != sqlSucceeded.charAt(i)) {
                System.out.println("Diff at index " + i + ": Failed char='" + sqlFailed.charAt(i) + "' (code " + (int)sqlFailed.charAt(i) + "), Succeeded char='" + sqlSucceeded.charAt(i) + "' (code " + (int)sqlSucceeded.charAt(i) + ")");
                break;
            }
        }
    }
}
