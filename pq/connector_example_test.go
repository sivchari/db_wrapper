// +build go1.10

package pq_test

import (
	"fmt"

	"github.com/sivchari/database/sql"

	"github.com/sivchari/database/pq"
)

func ExampleNewConnector() {
	name := ""
	connector, err := pq.NewConnector(name)
	if err != nil {
		fmt.Println(err)
		return
	}
	db := sql.OpenDB(connector)
	defer db.Close()

	// Use the DB
	txn, err := db.Begin()
	if err != nil {
		fmt.Println(err)
		return
	}
	txn.Rollback()
}
