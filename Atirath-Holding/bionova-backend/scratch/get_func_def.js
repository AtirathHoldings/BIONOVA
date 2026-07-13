const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgres://postgres.daaoeapbouspxcuprsqx:Atirath%402026@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function run() {
  await client.connect();
  try {
    const res = await client.query(`
      SELECT pg_get_functiondef('get_user_dashboard(bigint)'::regprocedure) AS def;
    `);
    console.log(res.rows[0].def);
  } catch (err) {
    console.error(err);
  } finally {
    await client.end();
  }
}

run();
