const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgres://postgres.daaoeapbouspxcuprsqx:Atirath%402026@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres',
  ssl: {
    rejectUnauthorized: false
  }
});

async function run() {
  await client.connect();
  try {
    console.log("Connected to database.");

    // Let's run a query to count total tasks for empId = 5 in task_live_master
    const liveTasksRes = await client.query(`
      SELECT task_id, task_nm, task_sts, emp_id 
      FROM task_live_master 
      WHERE (emp_id = 5 OR task_id IN (
        SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = 5 AND pc.is_live = true
      ))
    `);
    console.log("\n--- LIVE TASKS FOR EMP_ID = 5 (from task_live_master) ---");
    console.table(liveTasksRes.rows);

    const project6Res = await client.query(`
      SELECT prj_id, prj_nm, prj_sts 
      FROM project_live_master 
      WHERE prj_id = 6
    `);
    console.log("\n--- PROJECT 6 STATUS ---");
    console.table(project6Res.rows);

    // Let's count assignments for empId = 5
    const assignmentsRes = await client.query(`
      SELECT emp_task_id, task_nm, task_sts, emp_id, sts 
      FROM employee_individual_task_master 
      WHERE (emp_id = 5 OR emp_task_id IN (
        SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = 5 AND pc.emp_task_id IS NOT NULL
      )) AND COALESCE(sts, true) = true
    `);
    console.log("\n--- INDIVIDUAL ASSIGNMENTS FOR EMP_ID = 5 ---");
    console.table(assignmentsRes.rows);

    // Let's call get_user_dashboard(5)
    const dashboardRes = await client.query("SELECT get_user_dashboard(5) as data");
    console.log("\n--- get_user_dashboard(5) RAW DATA ---");
    console.log(JSON.stringify(dashboardRes.rows[0].data, null, 2));

  } catch (err) {
    console.error("Error executing query:", err);
  } finally {
    await client.end();
  }
}

run();
