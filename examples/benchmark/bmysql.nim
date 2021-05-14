import asyncdispatch, times
import ../../src/database/database

let db = open(MySQL, "database", "user", "Password!", "127.0.0.1", "3306", 100)
echo db.ping

proc main() {.async.} =
    let start = cpuTime()
    try:
      for i in 0..100:
        discard db.query("SELECT * FROM sample WHERE id = ?", 1)
    except:
      echo getCurrentExceptionMsg()
    echo cpuTime() - start
    # 0.009427999999999999

waitFor main()