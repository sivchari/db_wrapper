import cstrutils, macros, os, strutils, strformat

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
  PostgreSQL
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

proc getPath():string =
  echo currentSourcePath()
  result = currentSourcePath() / "../../sql.so"

proc getRowsCount(uptr:QueryRows):int {.cdecl, dynlib: getPath(), importc: "GetRowsCount".}

proc getColumnCount(uptr:QueryRows):int {.cdecl, dynlib: getPath(), importc: "GetColumnCount".}

proc getDriverName(uptr: DBConnection):cstring {.cdecl, dynlib: getPath(), importc: "GetDBDriverName".}

proc getDriverName(uptr: Transaction):cstring {.cdecl, dynlib: getPath(), importc: "GetTxDriverName".}

proc openDB(driverName, dataSourceName: cstring, connectionPool: cint = 1):DBConnection {.cdecl, dynlib: getPath(), importc: "DBOpen".}

proc open*(driver: Driver, database: cstring = "", user: cstring = "", password: cstring = "", host: cstring = "", port: cstring = "", connectionPool: int = 1):DBConnection =
  var driverName, dataSourceName: cstring
  var connPool: cint
  case driver:
  of MySQL:
    driverName = "mysql"
    dataSourceName = fmt"{user}:{password}@tcp({host}:{port})/{database}"
  of PostgreSQL:
    let sslmode = "disable"
    driverName = "postgres"
    dataSourceName = fmt"host={host} port={port} user={user} password={password} dbname={database} sslmode={sslmode}"
  of SQLite3:
    driverName = "sqlite3"
    dataSourceName = fmt"{database}"
  if connPool != 1: connPool = cast[cint](connectionPool)
  result = openDB(driverName, dataSourceName, connPool)

proc close*(uptr: DBConnection):bool {.cdecl, dynlib: getPath(), importc: "DBClose".}

proc ping*(uptr: DBConnection):bool {.cdecl, dynlib: getPath(), importc: "Ping".}

proc queryExec(uptr: DBConnection, query: cstring):QueryRows {.cdecl, dynlib: getPath(), importc: "QueryExec".}

proc queryExec(uptr: Transaction, query: cstring):QueryRows {.cdecl, dynlib: getPath(), importc: "TxQueryExec".}

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

proc prepare*(uptr: DBConnection, query: cstring):Stmt {.cdecl, dynlib: getPath(), importc: "StmtPrepare".}

proc prepare*(uptr: Transaction, query: cstring):Stmt {.cdecl, dynlib: getPath(), importc: "TxPrepare".}

proc stmtExec(uptr: Stmt, args: cstring):Result {.cdecl, dynlib: getPath(), importc: "StmtExec".}

proc exec*(uptr: Stmt, args: varargs[string, `$`]):Result =
  let q = stmtFormat(args)
  uptr.stmtExec(q)

proc getColumns(uptr: QueryRows):Columns {.cdecl, dynlib: getPath(), importc: "GetColumns".}

proc columnNames*(uptr: QueryRows):seq[string] =
  let columns = uptr.getColumns
  let len = uptr.getColumnCount
  var columnSeq = newSeq[string](len)
  for i in 0..len-1:
    columnSeq[i] = $columns[i]
  result = columnSeq

proc getTypes(uptr: QueryRows):Types {.cdecl, dynlib: getPath(), importc: "GetTypes".}

proc columnTypes*(uptr: QueryRows):seq[string] =
  let types = uptr.getTypes
  let len = uptr.getColumnCount
  newSeq(result, len)
  for i in 0..len-1:
    result[i] = $types[i]

proc getRow(uptr: QueryRows, i: int):Rows {.cdecl, dynlib: getPath(), importc: "GetRow".}

proc `[]`*(uptr: QueryRows, i: int):seq[string] =
  let row = uptr.getRow(i)
  let len = uptr.getColumnCount
  newSeq(result, len)
  for i in 0..len-1:
    result[i] = $row[i]

proc all*(uptr: QueryRows):seq[seq[string]] =
  let c = uptr.getRowsCount
  var rows: seq[seq[string]]
  for i in 0..<c:
    let row = uptr[i]
    rows.add(row)
  result = rows

proc beginTransaction*(uptr: DBConnection):Transaction {.cdecl, dynlib: getPath(), importc: "Begin".}

proc commit*(uptr: Transaction):bool {.cdecl, dynlib: getPath(), importc: "Commit".}

proc rollback*(uptr: Transaction):bool {.cdecl, dynlib: getPath(), importc: "Rollback".}

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
