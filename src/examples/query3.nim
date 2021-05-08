import ../database/connection

let db = connection.open("mysql", "user:Password!@tcp(127.0.0.1:3306)/database")
echo db.ping
echo "Connectted!"
echo "exec query"
let stmt = db.prepare("UPDATE sample SET en_name = ? WHERE id = ?")
discard stmt.exec("PreviousNim", 1)

let tx = db.beginTransaction
try:
  if isNil pointer(tx): discard
  let txstmt = tx.prepare("UPDATE sample SET en_name = ? WHERE id = ?")
  if isNil txstmt.exec("TxNim", 1): discard
  if not tx.commit: discard
except:
  if not tx.rollback: discard

let tx2 = db.beginTransaction
var
  e: ref OSError
new(e)
e.msg = "rollback"

try:
  if isNil pointer(tx2): discard
  let txstmt = tx2.prepare("UPDATE sample SET en_name = ? WHERE id = ?")
  if isNil txstmt.exec("RollbackNim", 1): discard
  raise e
except OSError:
  let
    e = getCurrentException()
    msg = getCurrentExceptionMsg()
  echo repr e, msg
  if not tx2.rollback: discard

let tx3 = db.beginTransaction

try:
  if isNil pointer(tx3): discard
  let row = tx3.query("SELECT * FROM sample WHERE id = ?", 1)
  echo row.columnNames
  echo row.columnTypes
  echo row[0]
  echo row.all
  if not tx3.commit: discard
except OSError:
  let
    e = getCurrentException()
    msg = getCurrentExceptionMsg()
  echo repr e, msg
  if not tx2.rollback: discard

discard db.close
