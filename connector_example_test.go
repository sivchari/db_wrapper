// +build go1.10

package main

import (
	"fmt"
)

func ExampleNewConnector() {
	name := ""
	connector, err := PQNewConnector(name)
	if err != nil {
		fmt.Println(err)
		return
	}
	uptr := openDB(connector)
	db := GetDBInstance(uptr)
	defer db.Close()

	// Use the DB
	txn, err := db.Begin()
	if err != nil {
		fmt.Println(err)
		return
	}
	txn.Rollback()
}
