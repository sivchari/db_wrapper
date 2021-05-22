import unittest
import ../../src/db as database

# write tests for failures.

let sqlite = open(SQLite3, "tests/db/sample.sqlite3")
echo "sqlite connected!"

block: # check ping
  check sqlite.ping == true
echo "Ping!"

# set up before test
let drop = "DROP TABLE IF EXISTS sample"
discard sqlite.query(drop)

let create = """CREATE TABLE IF NOT EXISTS `sample` (
   `id`  INT
  ,`age` INT
  ,`name` VARCHAR
  ,`time` TIMESTAMP NULL DEFAULT NULL
)"""
discard sqlite.query(create)

# table driven test
# IMO, I think that this test format makes the intent of the test clearer
# FYI: https://github.com/golang/go/wiki/TableDrivenTests
type struct = object
  name: string
  query: string
  args: seq[string]
  want: seq[string]

block: # check MySQL query
  let tests: seq[struct] = @[
     struct(
      name: "INSERT",
      query: "INSERT INTO sample(id, age, name, time) VALUES(?, ?, ?, ?)",
      args: @[$1, $10, "New Nim", "2016-01-01 00:00:00"],
      want: @[]
    ),
    struct(
      name: "SELECT",
      query: "SELECT * FROM sample WHERE id = ?",
      args: @[$1],
      want: @["1", "10", "New Nim", "2016-01-01 00:00:00"]
    ),
    struct(
      name: "DELETE",
      query: "DELETE FROM sample WHERE id = ?",
      args: @[$1],
      want: @[]
    ),
    struct(
      name: "INSERT",
      query: "INSERT INTO sample(id, age) VALUES(?, ?)",
      args: @[$1, $10],
      want: @[]
    ),
    struct(
      name: "SELECT",
      query: "SELECT * FROM sample WHERE id = ?",
      args: @[$1],
      want: @["1", "10", "", ""]
    ),
    struct(
      name: "UPDATE",
      query: "UPDATE sample SET name = ? WHERE id = ?",
      args: @["Change Nim", $1],
      want: @[]
    ),
    struct(
      name: "DELETE",
      query: "DELETE FROM sample WHERE id = ?",
      args: @[$1],
      want: @[]
    )
  ]

  for tt in items(tests): # run test
    var result: QueryRows
    if tt.name == "SELECT": result = sqlite.prepare(tt.query).query(tt.args)
    else: result = sqlite.prepare(tt.query).exec(tt.args)
    case tt.name
    of "INSERT":
      if isNil result: quit("FAILURE")
    of "SELECT":
      check result[0] == tt.want
      check result.all == @[result[0]]
      check result.columnTypes == ["INT", "INT", "VARCHAR", "TIMESTAMP"]
      check result.columnNames == ["id", "age", "name", "time"]
    of "UPDATE":
      if isNil result: quit("FAILURE")
    of "DELETE":
      if isNil result: quit("FAILURE")
    else: raise newException(Exception, "Unknow command")

block: # check MySQL prepare exec
  let tests: seq[struct] = @[
     struct(
      name: "INSERT",
      query: "INSERT INTO sample(id, age, name, time) VALUES(?, ?, ?, ?)",
      args: @[$1, $10, "New Nim", "2016-01-01 00:00:00"],
      want: @[]
    ),
    struct(
      name: "SELECT",
      query: "SELECT * FROM sample WHERE id = ?",
      args: @[$1],
      want: @["1", "10", "New Nim", "2016-01-01 00:00:00"]
    ),
    struct(
      name: "DELETE",
      query: "DELETE FROM sample WHERE id = ?",
      args: @[$1],
      want: @[]
    ),
    struct(
      name: "INSERT",
      query: "INSERT INTO sample(id, age) VALUES(?, ?)",
      args: @[$1, $10],
      want: @[]
    ),
    struct(
      name: "SELECT",
      query: "SELECT * FROM sample WHERE id = ?",
      args: @[$1],
      want: @["1", "10", "", ""]
    ),
    struct(
      name: "UPDATE",
      query: "UPDATE sample SET name = ? WHERE id = ?",
      args: @["Change Nim", $1],
      want: @[]
    ),
    struct(
      name: "DELETE",
      query: "DELETE FROM sample WHERE id = ?",
      args: @[$1],
      want: @[]
    ),
  ]

  for tt in items(tests): # run test
    var result: QueryRows
    if tt.name == "SELECT": result = sqlite.prepare(tt.query).query(tt.args)
    else: result = sqlite.prepare(tt.query).exec(tt.args)
    case tt.name
    of "INSERT":
      if isNil result: quit("FAILURE")
    of "SELECT":
      check result[0] == tt.want
      check result.all == @[result[0]]
      check result.columnTypes == ["INT", "INT", "VARCHAR", "TIMESTAMP"]
      check result.columnNames == ["id", "age", "name", "time"]
    of "UPDATE":
      if isNil result: quit("FAILURE")
    of "DELETE":
      if isNil result: quit("FAILURE")
    else: raise newException(Exception, "Unknow command")

# In the future, we will also write tests for manual transactions,
# but since manual transactions are used in macros, we are only testing macros now

block: # check Tx MySQL query
  let t1: struct = struct(
    name: "INSERT",
    query: "INSERT INTO sample(id, age, name, time) VALUES(?, ?, ?, ?)",
    args: @[$1, $10, "New Nim", "2016-01-01 00:00:00"],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.query(t1.query, t1.args)
    if isNil result: quit("FAILURE")

  let t2: struct = struct(
    name: "SELECT",
    query: "SELECT * FROM sample WHERE id = ?",
    args: @[$1],
    want: @["1", "10", "New Nim", "2016-01-01 00:00:00"]
  )
  sqlite.transaction:
    let result = sqlite.query(t2.query, t2.args)
    check result[0] == t2.want
    check result.all == @[result[0]]
    check result.columnTypes == ["INT", "INT", "VARCHAR", "TIMESTAMP"]
    check result.columnNames == ["id", "age", "name", "time"]
  
  let t3: struct = struct(
    name: "DELETE",
    query: "DELETE FROM sample WHERE id = ?",
    args: @[$1],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.query(t3.query, t3.args)
    if isNil result: quit("FAILURE")

  let t4: struct = struct(
    name: "INSERT",
    query: "INSERT INTO sample(id, age) VALUES(?, ?)",
    args: @[$1, $10],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.query(t4.query, t4.args)
    if isNil result: quit("FAILURE")

  let t5: struct = struct(
    name: "SELECT",
    query: "SELECT * FROM sample WHERE id = ?",
    args: @[$1],
    want: @["1", "10", "", ""]
  )
  sqlite.transaction:
    let result = sqlite.query(t5.query, t5.args)
    check result[0] == t5.want
    check result.all == @[result[0]]
    check result.columnTypes == ["INT", "INT", "VARCHAR", "TIMESTAMP"]
    check result.columnNames == ["id", "age", "name", "time"]

  let t6: struct = struct(
    name: "UPDATE",
    query: "UPDATE sample SET name = ? WHERE id = ?",
    args: @["Change Nim", $1],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.query(t6.query, t6.args)
    if isNil result: quit("FAILURE")

  let t7: struct = struct(
    name: "DELETE",
    query: "DELETE FROM sample WHERE id = ?",
    args: @[$1],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.query(t7.query, t7.args)
    if isNil result: quit("FAILURE")

block: # check Tx MySQL prepare exec
  let t1: struct = struct(
    name: "INSERT",
    query: "INSERT INTO sample(id, age, name) VALUES(?, ?, ?)",
    args: @[$1, $10, "New Nim"],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.prepare(t1.query).exec(t1.args)
    if isNil result: quit("FAILURE")

  let t2: struct = struct(
    name: "SELECT",
    query: "SELECT * FROM sample WHERE id = ?",
    args: @[$1],
    want: @["1", "10", "New Nim", ""]
  )
  sqlite.transaction:
    let result = sqlite.prepare(t2.query).query(t2.args)
    check result[0] == t2.want
    check result.all == @[result[0]]
    check result.columnTypes == ["INT", "INT", "VARCHAR", "TIMESTAMP"]
    check result.columnNames == ["id", "age", "name", "time"]
  
  let t3: struct = struct(
    name: "DELETE",
    query: "DELETE FROM sample WHERE id = ?",
    args: @[$1],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.prepare(t3.query).exec(t3.args)
    if isNil result: quit("FAILURE")

  let t4: struct = struct(
    name: "INSERT",
    query: "INSERT INTO sample(id, age) VALUES(?, ?)",
    args: @[$1, $10],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.prepare(t4.query).exec(t4.args)
    if isNil result: quit("FAILURE")

  let t5: struct = struct(
    name: "SELECT",
    query: "SELECT * FROM sample WHERE id = ?",
    args: @[$1],
    want: @["1", "10", "", ""]
  )
  sqlite.transaction:
    let result = sqlite.prepare(t5.query).query(t5.args)
    check result[0] == t5.want
    check result.all == @[result[0]]
    check result.columnTypes == ["INT", "INT", "VARCHAR", "TIMESTAMP"]
    check result.columnNames == ["id", "age", "name", "time"]

  let t6: struct = struct(
    name: "UPDATE",
    query: "UPDATE sample SET name = ? WHERE id = ?",
    args: @["Change Nim", $1],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.prepare(t6.query).exec(t6.args)
    if isNil result: quit("FAILURE")

  let t7: struct = struct(
    name: "DELETE",
    query: "DELETE FROM sample WHERE id = ?",
    args: @[$1],
    want: @[]
  )
  sqlite.transaction:
    let result = sqlite.prepare(t7.query).exec(t7.args)
    if isNil result: quit("FAILURE")

block: # check close
  check sqlite.close == true
