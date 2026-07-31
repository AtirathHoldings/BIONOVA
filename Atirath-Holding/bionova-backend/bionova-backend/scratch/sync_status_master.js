const { Client } = require('pg');

const client = new Client({
  connectionString: "postgresql://postgres.daaoeapbouspxcuprsqx:Atirath%402026@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true"
});

async function run() {
  try {
    await client.connect();
    console.log("Starting database transaction to sync task_status_master (no trigger disable)...");

    await client.query('BEGIN');

    // Update live tasks status references
    console.log("Migrating live tasks...");
    await client.query("UPDATE task_live_master SET task_sts = 3, sub_status = 'Under Review' WHERE task_sts = 4");
    await client.query("UPDATE task_live_master SET task_sts = 4, sub_status = 'Lead' WHERE task_sts = 5");
    await client.query("UPDATE task_live_master SET task_sts = 3, sub_status = 'Reassign' WHERE task_sts = 6");
    await client.query("UPDATE task_live_master SET task_sts = 3, sub_status = 'Rework' WHERE task_sts = 7");
    await client.query("UPDATE task_live_master SET task_sts = 2, sub_status = 'Overdue' WHERE task_sts = 8");

    // Update individual tasks status references
    console.log("Migrating individual tasks...");
    await client.query("UPDATE employee_individual_task_master SET task_sts = 3, sub_status = 'Under Review' WHERE task_sts = 4");
    await client.query("UPDATE employee_individual_task_master SET task_sts = 4, sub_status = 'Lead' WHERE task_sts = 5");
    await client.query("UPDATE employee_individual_task_master SET task_sts = 3, sub_status = 'Reassign' WHERE task_sts = 6");
    await client.query("UPDATE employee_individual_task_master SET task_sts = 3, sub_status = 'Rework' WHERE task_sts = 7");
    await client.query("UPDATE employee_individual_task_master SET task_sts = 2, sub_status = 'Overdue' WHERE task_sts = 8");

    // Update draft tasks status references
    console.log("Migrating draft tasks...");
    await client.query("UPDATE task_draft_master SET task_sts = 3, sub_status = 'Under Review' WHERE task_sts = 4");
    await client.query("UPDATE task_draft_master SET task_sts = 4, sub_status = 'Lead' WHERE task_sts = 5");
    await client.query("UPDATE task_draft_master SET task_sts = 3, sub_status = 'Reassign' WHERE task_sts = 6");
    await client.query("UPDATE task_draft_master SET task_sts = 3, sub_status = 'Rework' WHERE task_sts = 7");
    await client.query("UPDATE task_draft_master SET task_sts = 2, sub_status = 'Overdue' WHERE task_sts = 8");

    // Clear and insert into task_status_master
    console.log("Updating task_status_master rows...");
    // Let's delete and re-insert status IDs > 5
    await client.query("DELETE FROM task_status_master WHERE status_id > 5");
    await client.query(`
      INSERT INTO task_status_master (status_id, status_nm, sub_status_nm) VALUES
      (1, 'Draft', NULL),
      (2, 'Open', 'Overdue'),
      (3, 'WIP', 'Under Review, Reassign, Rework, Overdue'),
      (4, 'Completed', 'Lead, On Time, Lag'),
      (5, 'Hold', NULL)
      ON CONFLICT (status_id) DO UPDATE SET 
        status_nm = EXCLUDED.status_nm, 
        sub_status_nm = EXCLUDED.sub_status_nm
    `);

    await client.query('COMMIT');
    console.log("Transaction successfully committed!");

  } catch (err) {
    await client.query('ROLLBACK');
    console.error("Transaction failed and rolled back:", err);
  } finally {
    await client.end();
  }
}

run();
