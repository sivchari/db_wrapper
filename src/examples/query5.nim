import ../database/connection

let db = connection.open("postgres", "host=127.0.0.1 port=5432 user=user password=Password! dbname=database sslmode=disable", 1)
echo db.ping
echo "Connectted!"

discard db.query("INSERT INTO sample(age, ja_name, en_name) VALUES($1, $2, $3)", 10, "ぽすぐれ　にむ", "New Nim")
let stmt = db.prepare("UPDATE sample SET en_name = $1 WHERE id = $2")
discard stmt.exec("postgresNim", 1)

db.transaction:
  let stmt = db.prepare("UPDATE sample SET en_name = $1 WHERE id = $2")
  discard stmt.exec("Rollback Nim", 1)
  raise newException(Exception, "rollback")

let row = db.query("SELECT * FROM sample WHERE id = $1", 1)
echo row.columnNames
echo row.columnTypes
echo row[0]
echo row.all

discard db.close
