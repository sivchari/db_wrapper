import asyncdispatch, times
import ../../src/database/database

# time 2.45715, 1.858111, 2.194112, 1.90195, 1.982508
let db = open(PostgreSQL, "database", "user", "Password!", "127.0.0.1", "5432", 10)

proc asyncQuery(): Future[QueryRows] {.async.} =
  result = db.query("select * from sample")

proc main() {.async.} =
    let start = cpuTime()
    try:
      for i in 0..15000:
        asyncCheck asyncQuery()
    except:
      echo getCurrentExceptionMsg()
    echo cpuTime() - start

waitFor main()
