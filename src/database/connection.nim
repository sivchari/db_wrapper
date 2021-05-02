type
  GoDBConnection = pointer
  QueryRows = pointer

proc open(driverName, dataSourceName: cstring):GoDBConnection {.dynlib: "../../sql.so", importc: "Open".}
proc ping(uptr: GoDBConnection):cstring {.dynlib: "../../sql.so", importc: "Ping".}
proc query(uptr: GoDBConnection, query: cstring, args: cstring):QueryRows {.dynlib: "../../sql.so", importc: "Query1".}

let db = open("mysql", "user:Password!@tcp(127.0.0.1:3306)/database")
echo "Connectted!"
echo repr db
echo db.ping
echo "exec query"
let rows = db.query("SELECT count(*) FROM sample WHERE id = ? AND en_name = ?", "1, Nim")
echo repr rows
    