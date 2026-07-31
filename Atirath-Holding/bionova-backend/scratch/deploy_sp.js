const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

const javaFilePath = path.join(__dirname, '../src/main/java/com/bionova/config/DatabaseMigrator.java');
const javaContent = fs.readFileSync(javaFilePath, 'utf8');

// We find the starting position
const startText = 'CREATE OR REPLACE FUNCTION get_user_dashboard';
const startIndex = javaContent.indexOf(startText);
if (startIndex === -1) {
  console.error("Could not find start keyword in Java file.");
  process.exit(1);
}

// We will find all double-quoted strings starting from before the startText index
// Let's backtrack to find the opening quote of the starting line
let searchStart = javaContent.lastIndexOf('"', startIndex);

let sql = '';
let index = searchStart;
while (index < javaContent.length) {
  // Find next double quote
  const openQuote = javaContent.indexOf('"', index);
  if (openQuote === -1) break;
  
  // Find matching closing quote (ignoring escaped quotes)
  let closeQuote = openQuote + 1;
  while (closeQuote < javaContent.length) {
    if (javaContent[closeQuote] === '"' && javaContent[closeQuote - 1] !== '\\') {
      break;
    }
    closeQuote++;
  }
  
  if (closeQuote >= javaContent.length) break;
  
  const content = javaContent.substring(openQuote + 1, closeQuote);
  sql += content.replace(/\\"/g, '"').replace(/\\n/g, '\n');
  
  // Check if we hit get_admin_dashboard in the content we just read
  if (content.includes('get_admin_dashboard')) {
    break;
  }
  
  // Move index forward
  index = closeQuote + 1;
}

// Trim everything after the end of the SQL procedure ($$;)
const endMarker = '$$;';
const sqlEndIndex = sql.indexOf(endMarker);
if (sqlEndIndex !== -1) {
  sql = sql.substring(0, sqlEndIndex + endMarker.length);
}

console.log("Extracted SQL length:", sql.length);
console.log("SQL snippet:");
console.log(sql.substring(0, 500));
console.log("...");
console.log(sql.substring(sql.length - 200));

const client = new Client({
  connectionString: 'postgres://postgres.daaoeapbouspxcuprsqx:Atirath%402026@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function run() {
  await client.connect();
  try {
    console.log("\nAttempting to deploy extracted SQL to database...");
    await client.query(sql);
    console.log("SUCCESS: Stored procedure deployed successfully!");
  } catch (err) {
    console.error("FAILED to deploy stored procedure:", err);
  } finally {
    await client.end();
  }
}

run();
