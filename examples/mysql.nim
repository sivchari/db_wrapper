import ../src/db as database
import asyncdispatch

let db = open(MySQL, "database", "user", "Password!", "127.0.0.1", "3306", 10)
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

echo "next insert"
discard db.query("INSERT INTO sample(id, age, name) VALUES(?, ?, ?)", 1, 10, "New Nim")

proc asyncRow1():Future[QueryRows] {.async.} =
  echo "async1"
  await sleepAsync(1000)
  result = await db.asyncQuery("SELECT * FROM sample WHERE id = ?", @[$1])
  echo "async1 prepare exec"
  let stmt = await db.asyncPrepare("UPDATE sample SET name = ? WHERE id = ?")
  asyncCheck stmt.asyncExec(@["Nim", $1])
  echo "async1 transaction"
  db.transaction:
    let stmt = await db.asyncPrepare("UPDATE sample SET name = ? WHERE id = ?")
    asyncCheck stmt.asyncExec(@["Tx Nim", $1])
  echo "async1 end"

proc asyncRow2():Future[QueryRows] {.async.} =
  echo "async2"
  await sleepAsync(3000)
  result = await db.asyncQuery("SELECT * FROM sample WHERE id = ?", @[$1])
  echo "async2 prepare exec"
  let stmt = await db.asyncPrepare("UPDATE sample SET name = ? WHERE id = ?")
  asyncCheck stmt.asyncExec(@["Nim", $1])
  echo "async2 transaction"
  db.transaction:
    let stmt = await db.asyncPrepare("UPDATE sample SET name = ? WHERE id = ?")
    asyncCheck stmt.asyncExec(@["Tx Nim", $1])
  echo "async2 end"

proc asyncRow3():Future[QueryRows] {.async.} =
  echo "async3"
  await sleepAsync(2000)
  result = await db.asyncQuery("SELECT * FROM sample WHERE id = ?", @[$1])
  echo "async3 prepare exec"
  let stmt = await db.asyncPrepare("UPDATE sample SET name = ? WHERE id = ?")
  asyncCheck stmt.asyncExec(@["Nim", $1])
  echo "async3 transaction"
  db.transaction:
    let stmt = await db.asyncPrepare("UPDATE sample SET name = ? WHERE id = ?")
    asyncCheck stmt.asyncExec(@["Tx Nim", $1])
  await sleepAsync(2000)
  echo "async3 end"

proc main() {.async.} =
  try:
    echo "async"
    let a1 = asyncRow1()
    let a2 = asyncRow2()
    let a3 = asyncRow3()
    let results = await all(@[a1, a2, a3])
    for result in results:
      echo result[0]
    echo "async end"
  except:
    echo getCurrentExceptionMsg()

waitFor main()
discard db.close
