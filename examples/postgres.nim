import ../src/database

let db = open(PostgreSQL, "database", "user", "Password!", "127.0.0.1", "5432", 1)
echo db.ping

echo "insert"
discard db.query("INSERT INTO sample(id, age, name) VALUES(?, ?, ?)", 1, 10, "New Nim")

echo "select"
let row1 = db.query("SELECT * FROM sample WHERE id = ?", 1)
let row2 = db.prepare("SELECT * FROM sample WHERE id = ?").query(1)

echo row1.all
echo row1[0]
echo row1.columnTypes
echo row1.columnNames

echo row2.all
echo row2[0]
echo row2.columnTypes
echo row2.columnNames

echo "update"
let stmt1 = db.prepare("UPDATE sample SET name = ? WHERE id = ?")
discard stmt1.exec("Change Nim", 1)

echo "delete"
let stmt2 = db.prepare("DELETE FROM sample WHERE id = ?")
discard stmt2.exec(1)

echo "transaction"
db.transaction:
  let stmt3 = db.prepare("UPDATE sample SET name = ? WHERE id = ?")
  discard stmt3.exec("Rollback Nim", 1)
  raise newException(Exception, "rollback")

discard db.close
