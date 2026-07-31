const { Client } = require('pg');

const client = new Client({
  connectionString: "postgresql://postgres.daaoeapbouspxcuprsqx:Atirath%402026@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true"
});

async function run() {
  try {
    await client.connect();
    const res = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'task_live_master';
    `);
    console.log("Columns in task_live_master:");
    for (let row of res.rows) {
      console.log(`  ${row.column_name} (${row.data_type})`);
    }
  } catch (err) {
    console.error(err);
  } finally {
    await client.end();
  }
}

run();
