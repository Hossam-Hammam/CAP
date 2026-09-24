const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('bookshop.sqlite');

db.all("SELECT name,type FROM sqlite_master WHERE type IN ('table','view') ORDER BY type,name", (err, rows) => {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log(rows.map(r => r.type + ' ' + r.name).join('\n'));
  db.close();
});
