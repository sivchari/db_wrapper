// +build go1.10

package main

import (
	"fmt"
	"log"
)

func ExampleConnectorWithNoticeHandler() {
	name := ""
	// Base connector to wrap
	base, err := PQNewConnector(name)
	if err != nil {
		log.Fatal(err)
	}
	// Wrap the connector to simply print out the message
	connector := ConnectorWithNoticeHandler(base, func(notice *Error) {
		fmt.Println("Notice sent: " + notice.Message)
	})
	uptr := openDB(connector)
	db := GetDBInstance(uptr)
	defer db.Close()
	// Raise a notice
	sql := "DO language plpgsql $$ BEGIN RAISE NOTICE 'test notice'; END $$"
	if _, err := db.Exec(sql); err != nil {
		log.Fatal(err)
	}
	// Output:
	// Notice sent: test notice
}
