const { Client } = require('pg');

const client = new Client({
  connectionString: "postgresql://postgres.daaoeapbouspxcuprsqx:Atirath%402026@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true"
});

async function run() {
  try {
    await client.connect();

    console.log("=== TABLE: task_status_master ===");
    const res1 = await client.query('SELECT status_id, status_nm, sub_status_nm FROM task_status_master ORDER BY status_id ASC');
    console.table(res1.rows);

    console.log("\n=== TABLE: task_live_master (All Active Tasks) ===");
    const res2 = await client.query(`
      SELECT t.task_id, t.task_cd, t.task_nm, t.emp_id, 
             tsm.status_nm AS parent_status, t.sub_status
      FROM task_live_master t
      LEFT JOIN task_status_master tsm ON tsm.status_id = t.task_sts
      ORDER BY t.task_id::integer ASC
    `);
    console.table(res2.rows);

  } catch (err) {
    console.error(err);
  } finally {
    await client.end();
  }
}

run();
