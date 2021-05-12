import macros, strutils, strformat

type
  DBConnection = distinct pointer
  QueryRows = pointer
  Stmt = pointer
  Result = pointer
  Rows = cstringArray
  Columns = cstringArray
  Types = cstringArray
  Transaction = distinct pointer

type Driver* = enum
  MySQL
  Postgres
  SQLite3

proc dbQuote(s: string): string =
  ## DB quotes the string.
  result = newStringOfCap(s.len + 2)
  result.add "'"
  for c in items(s):
    # see https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html#mysql-escaping
    case c
    of '\0': result.add "\\0"
    of '\b': result.add "\\b"
    of '\t': result.add "\\t"
    of '\l': result.add "\\n"
    of '\r': result.add "\\r"
    of '\x1a': result.add "\\Z"
    of '"': result.add "\\\""
    of '\'': result.add "\\'"
    of '\\': result.add "\\\\"
    of '_': result.add "\\_"
    else: result.add c
  add(result, '\'')

proc dbFormat(formatstr: string, args: varargs[string, `$`]): string =
  result = ""
  var count = 0
  for c in items(formatstr):
    if c == '?':
      add(result, dbQuote(args[count]))
      inc(count)
    else:
      add(result, c)

proc pqDBFormat(formatstr: string, args: varargs[string, `$`]): string =
  result = formatstr
  var count = 0
  for c in items(formatStr):
    if c == '$':
      let placeNum = count + 1
      result = result.replace("$" & placeNum.intToStr, dbQuote(args[count]))
      inc(count)

proc stmtFormat(args: varargs[string, `$`]): string =
  result = ""
  let argsLen = args.len()
  var count = 1
  for c in items(args):
    if count == argsLen:
      add(result, c)
    else:
      add(result, c & ",")
      inc(count)

proc getCount(uptr:QueryRows):int {.dynlib: "../sql.so", importc: "GetCount".}

proc getDriverName(uptr: DBConnection):cstring {.dynlib: "../sql.so", importc: "GetDBDriverName".}

proc getDriverName(uptr: Transaction):cstring {.dynlib: "../sql.so", importc: "GetTxDriverName".}

proc openDB(driverName, dataSourceName: cstring, connectionPool: cint = 1):DBConnection {.dynlib: "../sql.so", importc: "DBOpen".}

proc open*(driver: Driver, database: cstring = "", user: cstring = "", password: cstring = "", host: cstring = "", port: cstring = "", connectionPool: int = 1):DBConnection =
  var driverName, dataSourceName: cstring
  var connPool: cint
  case driver:
  of MySQL:
    driverName = "mysql"
    dataSourceName = fmt"{user}:{password}@tcp({host}:{port})/{database}"
  of Postgres:
    let sslmode = "disable"
    driverName = "postgres"
    dataSourceName = fmt"host={host} port={port} user={user} password={password} dbname={database} sslmode={sslmode}"
  of SQLite3:
    driverName = "sqlite3"
    dataSourceName = fmt"{database}"
  if connPool != 1: connPool = cast[cint](connectionPool)
  result = openDB(driverName, dataSourceName, connPool)

proc close*(uptr: DBConnection):bool {.dynlib: "../sql.so", importc: "DBClose".}

proc ping*(uptr: DBConnection):bool {.dynlib: "../sql.so", importc: "Ping".}

proc queryExec(uptr: DBConnection, query: cstring):QueryRows {.dynlib: "../sql.so", importc: "QueryExec".}

proc queryExec(uptr: Transaction, query: cstring):QueryRows {.dynlib: "../sql.so", importc: "TxQueryExec".}

proc query*(uptr: DBConnection, query: string, args: varargs[string, `$`]):QueryRows =
  let d = uptr.getDriverName
  var q: string
  if d == "mysql": q = dbFormat(query, args)
  elif d == "postgres": q = pqDBFormat(query, args)
  elif d == "sqlite3": q = dbFormat(query, args)
  uptr.queryExec(q)

proc query*(uptr: Transaction, query: string, args: varargs[string, `$`]):QueryRows =
  let d = uptr.getDriverName
  var q: string
  if d == "mysql": q = dbFormat(query, args)
  elif d == "postgres": q = pqDBFormat(query, args)
  elif d == "sqlite3": q = dbFormat(query, args)
  uptr.queryExec(q)

proc prepare*(uptr: DBConnection, query: cstring):Stmt {.dynlib: "../sql.so", importc: "StmtPrepare".}

proc prepare*(uptr: Transaction, query: cstring):Stmt {.dynlib: "../sql.so", importc: "TxPrepare".}

proc stmtExec(uptr: Stmt, args: cstring):Result {.dynlib: "../sql.so", importc: "StmtExec".}

proc exec*(uptr: Stmt, args: varargs[string, `$`]):Result =
  let q = stmtFormat(args)
  uptr.stmtExec(q)

proc getColumns(uptr: QueryRows):Columns {.dynlib: "../sql.so", importc: "GetColumns".}

proc columnNames*(uptr: QueryRows):seq[string] =
  result = uptr.getColumns.cstringArrayToSeq

proc getTypes(uptr: QueryRows):Types {.dynlib: "../sql.so", importc: "GetTypes".}

proc columnTypes*(uptr: QueryRows):seq[string] =
  result = uptr.getTypes.cstringArrayToSeq

proc getRow(uptr: QueryRows, i: int):Rows {.dynlib: "../sql.so", importc: "GetRow".}

proc `[]`*(uptr: QueryRows, i: int):seq[string] =
  result = uptr.getRow(i).cstringArrayToSeq

proc all*(uptr: QueryRows):seq[seq[string]] =
  let c = uptr.getCount
  var rows: seq[seq[string]]
  for i in 0..<c:
    let row = uptr[i]
    rows.add(row)
  result = rows

proc beginTransaction*(uptr: DBConnection):Transaction {.dynlib: "../sql.so", importc: "Begin".}

proc commit*(uptr: Transaction):bool {.dynlib: "../sql.so", importc: "Commit".}

proc rollback*(uptr: Transaction):bool {.dynlib: "../sql.so", importc: "Rollback".}

macro transaction*(db: DBConnection, content: varargs[untyped]): untyped =
  var bodyStr = content.repr.replace("db", "tx")
  bodyStr = bodyStr.indent(2)
  bodyStr = fmt"""
block:
  let tx = db.beginTransaction
  if isNil pointer(tx): echo "failed to begin transaction"
  try:
    {bodyStr}
    if not tx.commit: echo "failed to commit"
  except:
    echo getCurrentExceptionMsg()
    if not tx.rollback: echo "failed to rollback"
"""
  result = bodyStr.parseStmt
