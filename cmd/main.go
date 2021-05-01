package main

import (
	"log"

	_ "github.com/sivchari/database/mysql"
	"github.com/sivchari/database/sql"
)

func main() {
	uptr := sql.Open("mysql", "user:Password!@tcp(127.0.0.1:3306)/database")
	db := sql.GetDBInstance(uptr)
	if db == nil {
		log.Fatal(db)
	}
	if err := sql.Ping(uptr); err != nil {
		log.Fatal(err)
	}
}
