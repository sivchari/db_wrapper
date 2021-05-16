import asyncdispatch, macros, os, strformat, strutils

# apple silicon or Intel
when defined(unix):
  when defined(macosx):
    when defined(amd64):
      const
        lib = "sql_amd64.so"
    when defined(arm64):
      const
        lib = "sql_arm64.so"
  else:
    const
      lib =  "sql_linux_amd64.so"
when defined(windows):
  const
    lib = "sql_windows_amd64.dll"

type
  DBConnection* = distinct pointer
  QueryRows* = pointer
  Stmt* = distinct pointer
  Result* = distinct pointer
  Rows* = cstringArray
  Columns* = cstringArray
  Types* = cstringArray
  Transaction* = distinct pointer

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

# TODO:: correspond to $* place holder
proc pqDBFormat(formatstr: string): string =
  result = ""
  var count = 1
  for c in items(formatStr):
    if c == '?':
      add(result, "$" & count.intToStr)
      inc(count)
    else:
      add(result, c)

proc stmtFormat(args: varargs[string, `$`]): string =
  result = ""
  let argsLen = args.len
  var count = 1
  for c in items(args):
    if count == argsLen:
      add(result, c)
    else:
      add(result, c & ",")
      inc(count)

proc getPath():string =
  result = currentSourcePath() / ".." / lib

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

proc queryExec(uptr: Stmt, args: cstring):QueryRows {.cdecl, dynlib: getPath(), importc: "StmtQuery".}

proc query*(uptr: DBConnection, query: string, args: varargs[string, `$`]):QueryRows =
  let d = uptr.getDriverName
  var q: string
  if d == "mysql": q = dbFormat(query, args)
  elif d == "postgres": q = dbFormat(query, args)
  elif d == "sqlite3": q = dbFormat(query, args)
  uptr.queryExec(q)

proc asyncQuery*(uptr: DBConnection, query: string, args: seq[string]):Future[QueryRows] {.async.} =
  result = uptr.query(query, args)

proc query*(uptr: Transaction, query: string, args: varargs[string, `$`]):QueryRows =
  let d = uptr.getDriverName
  var q: string
  if d == "mysql": q = dbFormat(query, args)
  elif d == "postgres": q = dbFormat(query, args)
  elif d == "sqlite3": q = dbFormat(query, args)
  uptr.queryExec(q)

proc asyncQuery*(uptr: Transaction, query: string, args: seq[string]):Future[QueryRows] {.async.} =
  result = uptr.query(query, args)

proc query*(uptr: Stmt, args: varargs[string, `$`]):QueryRows =
  let q = stmtFormat(args)
  uptr.queryExec(q)

proc asyncQuery*(uptr: Stmt, args: seq[string]):Future[QueryRows] {.async.} =
  result = uptr.query(args)

proc prepareExec(uptr: DBConnection, query: cstring):Stmt {.cdecl, dynlib: getPath(), importc: "StmtPrepare".}

proc prepare*(uptr: DBConnection, query: string):Stmt =
  let d = uptr.getDriverName
  if d == "mysql" or d == "sqlite3": result = uptr.prepareExec(query)
  elif d == "postgres": result = uptr.prepareExec(pqDBFormat(query))

proc asyncPrepare*(uptr: DBConnection, query: string):Future[Stmt] {.async.} =
  result = uptr.prepare(query)

proc prepareExec(uptr: Transaction, query: cstring):Stmt {.cdecl, dynlib: getPath(), importc: "TxPrepare".}

proc prepare*(uptr: Transaction, query: string):Stmt =
  let d = uptr.getDriverName
  if d == "mysql" or d == "sqlite3": result = uptr.prepareExec(query)
  elif d == "postgres": result = uptr.prepareExec(pqDBFormat(query))

proc asyncPrepare*(uptr: Transaction, query: string):Future[Stmt] {.async.} =
  result = uptr.prepare(query)

proc stmtExec(uptr: Stmt, args: cstring):QueryRows {.cdecl, dynlib: getPath(), importc: "StmtExec".}

proc stmtExec(uptr: Future[Stmt], args: cstring):Future[QueryRows] {.async, cdecl, dynlib: getPath(), importc: "StmtExec".}

proc exec*(uptr: Stmt, args: varargs[string, `$`]):QueryRows =
  let q = stmtFormat(args)
  uptr.stmtExec(q)

proc exec(uptr: Future[Stmt], args: seq[string]):Future[QueryRows] {.async.} =
  let q = stmtFormat(args)
  result = await uptr.stmtExec(q)

proc asyncExec*(uptr: Stmt, args: seq[string]):Future[QueryRows] {.async.} =
  result = uptr.exec(args)

proc asyncExec*(uptr: Future[Stmt], args: seq[string]):Future[QueryRows] {.async.} =
  result = await uptr.exec(args)

proc getColumns(uptr: QueryRows):Columns {.cdecl, dynlib: getPath(), importc: "GetColumns".}

proc columnNames*(uptr: QueryRows):seq[string] =
  let columns = uptr.getColumns
  let len = uptr.getColumnCount
  var columnSeq = newSeq[string](len)
  for i in 0..len-1:
    columnSeq[i] = $columns[i]
  result = columnSeq

proc asyncColumnNames*(uptr: QueryRows):Future[seq[string]] {.async.} =
  result = uptr.columnNames

proc getTypes(uptr: QueryRows):Types {.cdecl, dynlib: getPath(), importc: "GetTypes".}

proc columnTypes*(uptr: QueryRows):seq[string] =
  let types = uptr.getTypes
  let len = uptr.getColumnCount
  newSeq(result, len)
  for i in 0..len-1:
    result[i] = $types[i]

proc asyncColumnTypes*(uptr: QueryRows):Future[seq[string]] {.async.} =
  result = uptr.columnTypes

proc getRow(uptr: QueryRows, i: int):Rows {.cdecl, dynlib: getPath(), importc: "GetRow".}

proc `[]`*(uptr: QueryRows, i: int):seq[string] =
  let row = uptr.getRow(i)
  let len = uptr.getColumnCount
  newSeq(result, len)
  for i in 0..len-1:
    result[i] = $row[i]

proc asyncGetRow*(uptr: QueryRows, i: int):Future[seq[string]] {.async.} =
  result = uptr.`[]`(i)

proc all*(uptr: QueryRows):seq[seq[string]] =
  let c = uptr.getRowsCount
  var rows: seq[seq[string]]
  for i in 0..<c:
    let row = uptr[i]
    rows.add(row)
  result = rows

proc asyncAll*(uptr: QueryRows):Future[seq[seq[string]]] {.async.} =
  result = uptr.all

proc beginTransaction*(uptr: DBConnection):Transaction {.cdecl, dynlib: getPath(), importc: "Begin".}

proc commit*(uptr: Transaction):bool {.cdecl, dynlib: getPath(), importc: "Commit".}

proc rollback*(uptr: Transaction):bool {.cdecl, dynlib: getPath(), importc: "Rollback".}

macro transaction*(db: DBConnection, content: varargs[untyped]): untyped =
  var bodyStr = content.repr.replace(fmt"{db}.", "tx.")
  bodyStr.removePrefix
  bodyStr = bodyStr.indent(2)
  bodyStr = fmt"""
block:
  let tx = {db}.beginTransaction
  if isNil pointer(tx): echo "failed to begin transaction"
  try:
{bodyStr}
    if not tx.commit: echo "failed to commit"
  except:
    echo getCurrentExceptionMsg()
    if not tx.rollback: echo "failed to rollback"
"""
  result = bodyStr.parseStmt
