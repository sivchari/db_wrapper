import ../database/connection

let db = connection.open(MySQL, "database", "user", "Password!", "127.0.0.1", "3306", 10)
echo db.ping
echo "Connectted!"
echo "exec query"
let row = db.query("SELECT * FROM sample WHERE id = ?", 1)

let r = row[0]

echo r
echo row.columnNames
echo row.columnTypes
echo row.all

db.transaction:
  let stmt = db.prepare("UPDATE sample SET en_name = ? WHERE id = ?")
  discard stmt.exec("Rollback Nim", 1)
  raise newException(Exception, "rollback")
