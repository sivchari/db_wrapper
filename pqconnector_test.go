// +build go1.10

package main

import (
	"context"
	"testing"

	"github.com/sivchari/database/driver"
)

func TestNewConnector_WorksWithOpenDB(t *testing.T) {
	name := ""
	c, err := PQNewConnector(name)
	if err != nil {
		t.Fatal(err)
	}
	uptr := openDB(c)
	db := GetDBInstance(uptr)
	defer db.Close()
	// database/.sql might not call our Open at all unless we do something with
	// the connection
	txn, err := db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	txn.Rollback()
}

func TestNewConnector_Connect(t *testing.T) {
	name := ""
	c, err := PQNewConnector(name)
	if err != nil {
		t.Fatal(err)
	}
	db, err := c.Connect(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	// database/.sql might not call our Open at all unless we do something with
	// the connection
	txn, err := db.(driver.ConnBeginTx).BeginTx(context.Background(), driver.TxOptions{})
	if err != nil {
		t.Fatal(err)
	}
	txn.Rollback()
}

func TestNewConnector_Driver(t *testing.T) {
	name := ""
	c, err := PQNewConnector(name)
	if err != nil {
		t.Fatal(err)
	}
	db, err := c.Driver().Open(name)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	// database/.sql might not call our Open at all unless we do something with
	// the connection
	txn, err := db.(driver.ConnBeginTx).BeginTx(context.Background(), driver.TxOptions{})
	if err != nil {
		t.Fatal(err)
	}
	txn.Rollback()
}
