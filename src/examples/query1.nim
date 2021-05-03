import ../database/connection

let db = connection.open("mysql", "user:Password!@tcp(127.0.0.1:3306)/database")
echo "Connectted!"
echo repr db
echo db.ping
echo "exec query"
discard db.query("UPDATE sample SET en_name = ? WHERE id = ?", "nim", 1)