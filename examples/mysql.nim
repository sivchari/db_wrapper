import ../src/database/database

let db = open(MySQL, "database", "user", "Password!", "127.0.0.1", "3306", 10)
echo db.ping

echo "insert"
discard db.query("INSERT INTO sample(id, age, name) VALUES(?, ?, ?)", 1, 10, "New Nim")

echo "select"
let row = db.query("SELECT * FROM sample WHERE id = ?", 1)

echo "update"
let stmt1 = db.prepare("UPDATE sample SET name = ? WHERE id = ?")
discard stmt1.exec("Change Nim", 1)

echo "delete"
let stmt2 = db.prepare("DELETE FROM sample WHERE id = ?")
discard stmt2.exec(1)

echo row.all
echo row[0]
echo row.columnTypes
echo row.columnNames

db.transaction:
  let stmt3 = db.prepare("UPDATE sample SET name = ? WHERE id = ?")
  discard stmt3.exec("Rollback Nim", 1)
  raise newException(Exception, "rollback")

discard db.close
