-- =============================================================================
-- BIONOVA DATABASE INDEXING OPTIMIZATION SCRIPT
-- Executes CREATE INDEX IF NOT EXISTS for key query columns in web and app APIs.
-- =============================================================================

-- 1. Employee Master Indexes
CREATE INDEX IF NOT EXISTS idx_emp_email ON employee_master(email);
CREATE INDEX IF NOT EXISTS idx_emp_coy_id ON employee_master(coy_id);
CREATE INDEX IF NOT EXISTS idx_emp_plt_id ON employee_master(plt_id);
CREATE INDEX IF NOT EXISTS idx_emp_dept_id ON employee_master(dept_id);
CREATE INDEX IF NOT EXISTS idx_emp_desig_id ON employee_master(desig_id);
CREATE INDEX IF NOT EXISTS idx_emp_prnt_coy_id ON employee_master(prnt_coy_id);

-- 2. Individual Tasks / Assignments Indexes
CREATE INDEX IF NOT EXISTS idx_asgn_emp_id ON employee_individual_task_master(emp_id);
CREATE INDEX IF NOT EXISTS idx_asgn_assigned_by ON employee_individual_task_master(assigned_by);
CREATE INDEX IF NOT EXISTS idx_asgn_coy_id ON employee_individual_task_master(coy_id);
CREATE INDEX IF NOT EXISTS idx_asgn_task_sts ON employee_individual_task_master(task_sts);

-- 3. Live Tasks Indexes
CREATE INDEX IF NOT EXISTS idx_task_live_m_id ON task_live_master(m_id);
CREATE INDEX IF NOT EXISTS idx_task_live_emp_id ON task_live_master(emp_id);
CREATE INDEX IF NOT EXISTS idx_task_live_assigned_by ON task_live_master(assigned_by);
CREATE INDEX IF NOT EXISTS idx_task_live_task_sts ON task_live_master(task_sts);

-- 4. Live Milestones Indexes
CREATE INDEX IF NOT EXISTS idx_mls_live_prj_id ON milestone_live_master(prj_id);
CREATE INDEX IF NOT EXISTS idx_mls_live_mlstn_sts ON milestone_live_master(mlstn_sts);

-- 5. Live Projects Indexes
CREATE INDEX IF NOT EXISTS idx_prj_live_coy_id ON project_live_master(coy_id);
CREATE INDEX IF NOT EXISTS idx_prj_live_prj_sts ON project_live_master(prj_sts);

-- 6. Process Config Indexes
CREATE INDEX IF NOT EXISTS idx_pc_task_id_live ON process_config(task_id, is_live);
CREATE INDEX IF NOT EXISTS idx_pc_emp_task_id ON process_config(emp_task_id);
CREATE INDEX IF NOT EXISTS idx_pc_emp_id ON process_config(emp_id);

-- 7. Notifications & Activity Logs
CREATE INDEX IF NOT EXISTS idx_notif_recipient ON notifications(recipient_emp_id, is_read);
CREATE INDEX IF NOT EXISTS idx_act_emp_id ON activity_logs(emp_id);

-- 8. RBAC Mapping & Security
CREATE INDEX IF NOT EXISTS idx_rb_emp_id ON role_based_employee_mapping(emp_id);
CREATE INDEX IF NOT EXISTS idx_rbac_role_id ON role_based_access_control(role_id);
