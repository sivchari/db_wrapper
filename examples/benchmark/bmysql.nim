import asyncdispatch, times
import ../../src/database/database

# time 2.205213, 2.140853, 2.212488, 2.33294, 2.242372
let db = open(MySQL, "database", "user", "Password!", "127.0.0.1", "3306", 151)

proc asyncQuery(): Future[QueryRows] {.async.} =
  result = db.query("select * from sample")
  await sleepAsync(100)

proc main() {.async.} =
  let start = cpuTime()
  try:
    for i in 0..15000:
      asyncCheck asyncQuery()
  except:
    echo getCurrentExceptionMsg()
  echo cpuTime() - start

waitFor main()
