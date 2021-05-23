import unittest
import ../../src/db_wrapper

# write tests for failures.

let postgres = open(PostgreSQL, "database", "user", "Password!", "127.0.0.1", "5432", 1)
echo "postgres connected!"

block: # check ping
  check postgres.ping == true
echo "Ping!"

# set up before test
let drop = "DROP TABLE IF EXISTS sample"
discard postgres.query(drop)

let create = """create table sample (
  id integer not null,
  age integer not null,
  name varchar null,
  time timestamp null
)"""
discard postgres.query(create)

# table driven test
# IMO, I think that this test format makes the intent of the test clearer
# FYI: https://github.com/golang/go/wiki/TableDrivenTests
type struct = object
  name: string
  query: string
  args: seq[string]
  want: seq[string]

block: # check PostgreSQL query
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
    if tt.name == "SELECT": result = postgres.prepare(tt.query).query(tt.args)
    else: result = postgres.prepare(tt.query).exec(tt.args)
    case tt.name
    of "INSERT":
      if isNil result: quit("FAILURE")
    of "SELECT":
      check result[0] == tt.want
      check result.all == @[result[0]]
      check result.columnTypes == ["INT4", "INT4", "VARCHAR", "TIMESTAMP"]
      check result.columnNames == ["id", "age", "name", "time"]
    of "UPDATE":
      if isNil result: quit("FAILURE")
    of "DELETE":
      if isNil result: quit("FAILURE")
    else: raise newException(Exception, "Unknow command")

block: # check PostgreSQL prepare exec
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
    if tt.name == "SELECT": result = postgres.prepare(tt.query).query(tt.args)
    else: result = postgres.prepare(tt.query).exec(tt.args)
    case tt.name
    of "INSERT":
      if isNil result: quit("FAILURE")
    of "SELECT":
      check result[0] == tt.want
      check result.all == @[result[0]]
      check result.columnTypes == ["INT4", "INT4", "VARCHAR", "TIMESTAMP"]
      check result.columnNames == ["id", "age", "name", "time"]
    of "UPDATE":
      if isNil result: quit("FAILURE")
    of "DELETE":
      if isNil result: quit("FAILURE")
    else: raise newException(Exception, "Unknow command")

# In the future, we will also write tests for manual transactions,
# but since manual transactions are used in macros, we are only testing macros now

block: # check Tx PostgreSQL query
  let t1: struct = struct(
    name: "INSERT",
    query: "INSERT INTO sample(id, age, name) VALUES(?, ?, ?)",
    args: @[$1, $10, "New Nim"],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.query(t1.query, t1.args)
    if isNil result: quit("FAILURE")

  let t2: struct = struct(
    name: "SELECT",
    query: "SELECT * FROM sample WHERE id = ?",
    args: @[$1],
    want: @["1", "10", "New Nim", ""]
  )
  postgres.transaction:
    let result =  postgres.query(t2.query, t2.args)
    check result[0] == t2.want
    check result.all == @[result[0]]
    check result.columnTypes == ["INT4", "INT4", "VARCHAR", "TIMESTAMP"]
    check result.columnNames == ["id", "age", "name", "time"]
  
  let t3: struct = struct(
    name: "DELETE",
    query: "DELETE FROM sample WHERE id = ?",
    args: @[$1],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.query(t3.query, t3.args)
    if isNil result: quit("FAILURE")
  
  let t4: struct = struct(
    name: "INSERT",
    query: "INSERT INTO sample(id, age) VALUES(?, ?)",
    args: @[$1, $10],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.query(t4.query, t4.args)
    if isNil result: quit("FAILURE")

  let t5: struct = struct(
    name: "SELECT",
    query: "SELECT * FROM sample WHERE id = ?",
    args: @[$1],
    want: @["1", "10", "", ""]
  )
  postgres.transaction:
    let result = postgres.query(t5.query, t5.args)
    check result[0] == t5.want
    check result.all == @[result[0]]
    check result.columnTypes == ["INT4", "INT4", "VARCHAR", "TIMESTAMP"]
    check result.columnNames == ["id", "age", "name", "time"]

  let t6: struct = struct(
    name: "UPDATE",
    query: "UPDATE sample SET name = ? WHERE id = ?",
    args: @["Change Nim", $1],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.query(t6.query, t6.args)
    if isNil result: quit("FAILURE")
  
  let t7: struct = struct(
    name: "DELETE",
    query: "DELETE FROM sample WHERE id = ?",
    args: @[$1],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.query(t7.query, t7.args)
    if isNil result: quit("FAILURE")

block: # check Tx PostgreSQL prepare exec
  let t1: struct = struct(
    name: "INSERT",
    query: "INSERT INTO sample(id, age, name) VALUES(?, ?, ?)",
    args: @[$1, $10, "New Nim"],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.prepare(t1.query).exec(t1.args)
    if isNil result: quit("FAILURE")

  let t2: struct = struct(
    name: "SELECT",
    query: "SELECT * FROM sample WHERE id = ?",
    args: @[$1],
    want: @["1", "10", "New Nim", ""]
  )
  postgres.transaction:
    let result = postgres.prepare(t2.query).query(t2.args)
    check result[0] == t2.want
    check result.all == @[result[0]]
    check result.columnTypes == ["INT4", "INT4", "VARCHAR", "TIMESTAMP"]
    check result.columnNames == ["id", "age", "name", "time"]
  
  let t3: struct = struct(
    name: "DELETE",
    query: "DELETE FROM sample WHERE id = ?",
    args: @[$1],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.query(t3.query, t3.args)
    if isNil result: quit("FAILURE")
  
  let t4: struct = struct(
    name: "INSERT",
    query: "INSERT INTO sample(id, age) VALUES(?, ?)",
    args: @[$1, $10],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.prepare(t4.query).exec(t4.args)
    if isNil result: quit("FAILURE")
  
  let t5: struct = struct(
    name: "SELECT",
    query: "SELECT * FROM sample WHERE id = ?",
    args: @[$1],
    want: @["1", "10", "", ""]
  )
  postgres.transaction:
    let result = postgres.prepare(t5.query).query(t5.args)
    check result[0] == t5.want
    check result.all == @[result[0]]
    check result.columnTypes == ["INT4", "INT4", "VARCHAR", "TIMESTAMP"]
    check result.columnNames == ["id", "age", "name", "time"]

  let t6: struct = struct(
    name: "UPDATE",
    query: "UPDATE sample SET name = ? WHERE id = ?",
    args: @["Change Nim", $1],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.prepare(t6.query).exec(t6.args)
    if isNil result: quit("FAILURE")
  
  let t7: struct = struct(
    name: "DELETE",
    query: "DELETE FROM sample WHERE id = ?",
    args: @[$1],
    want: @[]
  )
  postgres.transaction:
    let result = postgres.prepare(t7.query).exec(t7.args)
    if isNil result: quit("FAILURE")

block: # check close
  check postgres.close == true
