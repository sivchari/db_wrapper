import ../database/connection

let db = connection.open("mysql", "user:Password!@tcp(127.0.0.1:3306)/database")
echo db.ping
echo "Connectted!"
echo "exec query"
let row = db.query("SELECT * FROM sample WHERE id = ?", 1)


let r = row[0]

echo r.cstringArrayToSeq
echo row.getColumns.cstringArrayToSeq
echo row.getTypes.cstringArrayToSeq
echo row.all
