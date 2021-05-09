import ../database/connection

let db = connection.open("mysql", "user:Password!@tcp(127.0.0.1:3306)/database")
echo db.ping
echo "Connectted!"

db.transaction:
  let stmt = db.prepare("UPDATE sample SET en_name = ? WHERE id = ?")
  discard stmt.exec("Rollback Nim", 1)
  raise newException(Exception, "rollback")

db.transaction:
  let stmt = db.prepare("UPDATE sample SET en_name = ? WHERE id = ?")
  discard stmt.exec("Rollback Nim", 1)
  raise newException(Exception, "rollback")

discard db.close
