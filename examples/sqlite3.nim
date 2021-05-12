import ../src/database/database

let db = open(SQLite3, "sample.sqlite3")
echo db.ping

let cmd = """CREATE TABLE IF NOT EXISTS sample (
     id INT
    ,age INT
    ,name VARCHAR
)"""

discard db.query(cmd)

echo "insert"
discard db.query("INSERT INTO sample(id, age, name) VALUES(?, ?, ?)", 1, 10, "New Nim")

echo "select"
let row = db.query("SELECT * FROM sample WHERE id = ?", 1)

echo "update"
let stmt1 = db.prepare("UPDATE sample SET name = ? WHERE id = ?")
discard stmt1.exec("Change Nim", 1)

echo "delete"
let stmt2 = db.prepare("DELETE FROM sample WHERE id = ?")
discard stmt2.exec(1)

echo row.all
echo row[0]
echo row.columnTypes
echo row.columnNames

discard db.close
