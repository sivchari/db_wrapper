type
  GoDBConnection = pointer

proc open(driverName, dataSourceName: cstring):GoDBConnection {.dynlib: "../../sql.so", importc: "Open".}
proc ping(uptr: GoDBConnection):cstring {.dynlib: "../../sql.so", importc: "Ping".}

let db = open("mysql", "user:Password!@tcp(127.0.0.1:3306)/database")
echo "Connectted!"
echo repr db
echo db.ping
    