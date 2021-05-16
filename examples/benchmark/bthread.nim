import times, threadpool
import ../../src/database

let db = open(MySQL, "database", "user", "Password!", "127.0.0.1", "3306", 100)

proc asyncQuery(): QueryRows =
  result = db.query("select * from sample")

proc main() =
  let start = cpuTime()
  try:
    for i in 0..150000:
      discard spawn asyncQuery()
  except:
    echo getCurrentExceptionMsg()
  echo cpuTime() - start
  sync()
main()
