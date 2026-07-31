-- =============================================================
-- screen_master seed data
-- Run this ONCE on the database to populate all screens.
-- The screen_code values MUST match what is used in sidebar.jsx
-- =============================================================

INSERT INTO screen_master (screen_nm, group_nm, screen_code, sts) VALUES
-- Company Master group
('Admin Dashboard',    'Company Master', 'ADMIN_DASHBOARD',   true),
('Company Creation',   'Company Master', 'COMPANY_CREATION',  true),
('Plant Creation',     'Company Master', 'PLANT_CREATION',    true),
('Land Creation',      'Company Master', 'LAND_CREATION',     true),
('Employee Creation',  'Company Master', 'EMPLOYEE_CREATION', true),
('Department Creation','Company Master', 'DEPT_CREATION',     true),
('Department Mapping', 'Company Master', 'DEPT_MAPPING',      true),
-- Project group
('Project Creation',          'Project', 'PROJECT_CREATION',    true),
('Milestone & Task Creation', 'Project', 'MILESTONE_CREATION',  true),
('Project Dashboard',         'Project', 'PROJECT_DASHBOARD',   true),
('Project List',              'Project', 'PROJECT_LIST',        true),
('Individual Task',           'Project', 'INDIVIDUAL_TASK',     true),
('Task Board',                'Project', 'TASK_BOARD',          true),
-- User group
('User Dashboard', 'User', 'USER_DASHBOARD', true),
('My Task',        'User', 'MY_TASK',        true),
('Calendar',       'User', 'CALENDAR',       true),
('My Project',     'User', 'MY_PROJECT',     true),
-- Other Settings
('Public Holidays', 'Other Settings', 'PUBLIC_HOLIDAYS', true),
('Assign Access',   'Other Settings', 'ASSIGN_ACCESS',   true),
('Project Access',  'Other Settings', 'PROJECT_ACCESS',  true),
('Profile',         'Other Settings', 'PROFILE',         true),
ON CONFLICT (screen_code) DO NOTHING;
