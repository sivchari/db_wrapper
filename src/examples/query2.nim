import ../database/connection

let db = connection.open("mysql", "user:Password!@tcp(127.0.0.1:3306)/database")
echo db.ping
echo "Connectted!"
echo "exec query"
let stmt = db.prepare("UPDATE sample SET en_name = ? WHERE id = ?")
discard stmt.exec("NNNim", 1)