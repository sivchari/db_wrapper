import ../database/connection

let db = connection.open("sqlite3", "sample.sqlite3")
echo db.ping
echo "Connectted!"

let cmd = """CREATE TABLE sample (
     id  INTEGER
    ,age INTEGER
    ,ja_name  STRING
    ,en_name  STRING
)"""

discard db.query(cmd)

echo "insert"
discard db.query("INSERT INTO sample(id, age, ja_name, en_name) VALUES(?, ?, ?, ?)", 1, 10, "sqlite にむ", "sqlite3 Nim")

echo "update"
let stmt = db.prepare("UPDATE sample SET en_name = ? WHERE id = ?")
discard stmt.exec("NNNim", 1)

echo "select"
let row = db.query("SELECT * FROM sample WHERE id = ?", 1)

echo row.all
echo row[0]
echo row.columnTypes
echo row.columnNames
