const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgres://postgres.daaoeapbouspxcuprsqx:Atirath%402026@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function run() {
  await client.connect();
  try {
    const query = `
      SELECT 
        t.task_id, 
        t.task_nm, 
        tsm.status_nm, 
        'PROJECT' AS source,
        t.emp_id
      FROM task_live_master t 
      LEFT JOIN milestone_live_master m ON m.m_id = t.m_id 
      LEFT JOIN project_live_master p ON p.prj_id = m.prj_id 
      LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
      WHERE (t.emp_id = 5 OR t.task_id IN ( 
        SELECT pc.task_id FROM process_config pc WHERE pc.emp_id = 5 AND pc.is_live = true 
      ))

      UNION ALL 

      SELECT 
        t.emp_task_id AS task_id, 
        t.task_nm, 
        tsm.status_nm, 
        'INDIVIDUAL' AS source,
        t.emp_id
      FROM employee_individual_task_master t 
      LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts 
      WHERE (t.emp_id = 5 OR t.emp_task_id IN ( 
        SELECT pc.emp_task_id FROM process_config pc WHERE pc.emp_id = 5 AND pc.emp_task_id IS NOT NULL 
      )) AND COALESCE(t.sts, true) = true 
    `;
    const res = await client.query(query);
    console.table(res.rows);
  } catch (err) {
    console.error(err);
  } finally {
    await client.end();
  }
}

run();
