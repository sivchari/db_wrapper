import asyncdispatch, times
import ../../src/db_wrapper

# time 0.301291, 0.284612, 0.28805, 0.285741, 0.26572
let db = open(SQLite3, "sample.sqlite3")

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