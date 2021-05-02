package main

import (
	"context"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/sivchari/database/driver"
)

func TestMultipleSimpleQuery(t *testing.T) {
	db := openTestConn(t)
	defer db.Close()

	rows, err := db.Query("select 1; set time zone default; select 2; select 3")
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()

	var i int
	for rows.Next() {
		if err := rows.Scan(&i); err != nil {
			t.Fatal(err)
		}
		if i != 1 {
			t.Fatalf("expected 1, got %d", i)
		}
	}
	if !rows.NextResultSet() {
		t.Fatal("expected more result sets", rows.Err())
	}
	for rows.Next() {
		if err := rows.Scan(&i); err != nil {
			t.Fatal(err)
		}
		if i != 2 {
			t.Fatalf("expected 2, got %d", i)
		}
	}

	// Make sure that if we ignore a result we can still query.

	rows, err = db.Query("select 4; select 5")
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()

	for rows.Next() {
		if err := rows.Scan(&i); err != nil {
			t.Fatal(err)
		}
		if i != 4 {
			t.Fatalf("expected 4, got %d", i)
		}
	}
	if !rows.NextResultSet() {
		t.Fatal("expected more result sets", rows.Err())
	}
	for rows.Next() {
		if err := rows.Scan(&i); err != nil {
			t.Fatal(err)
		}
		if i != 5 {
			t.Fatalf("expected 5, got %d", i)
		}
	}
	if rows.NextResultSet() {
		t.Fatal("unexpected result set")
	}
}

const contextRaceIterations = 100

func TestGo18ContextCancelExec(t *testing.T) {
	db := openTestConn(t)
	defer db.Close()

	ctx, cancel := context.WithCancel(context.Background())

	// Delay execution for just a bit until db.ExecContext has begun.
	defer time.AfterFunc(time.Millisecond*10, cancel).Stop()

	// Not canceled until after the exec has started.
	if _, err := db.ExecContext(ctx, "select pg_sleep(1)"); err == nil {
		t.Fatal("expected error")
	} else if err.Error() != "pq: canceling statement due to user request" {
		t.Fatalf("unexpected error: %s", err)
	}

	// Context is already canceled, so error should come before execution.
	if _, err := db.ExecContext(ctx, "select pg_sleep(1)"); err == nil {
		t.Fatal("expected error")
	} else if err.Error() != "context canceled" {
		t.Fatalf("unexpected error: %s", err)
	}

	for i := 0; i < contextRaceIterations; i++ {
		func() {
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()
			if _, err := db.ExecContext(ctx, "select 1"); err != nil {
				t.Fatal(err)
			}
		}()

		if _, err := db.Exec("select 1"); err != nil {
			t.Fatal(err)
		}
	}
}

func TestGo18ContextCancelQuery(t *testing.T) {
	db := openTestConn(t)
	defer db.Close()

	ctx, cancel := context.WithCancel(context.Background())

	// Delay execution for just a bit until db.QueryContext has begun.
	defer time.AfterFunc(time.Millisecond*10, cancel).Stop()

	// Not canceled until after the exec has started.
	if _, err := db.QueryContext(ctx, "select pg_sleep(1)"); err == nil {
		t.Fatal("expected error")
	} else if err.Error() != "pq: canceling statement due to user request" {
		t.Fatalf("unexpected error: %s", err)
	}

	// Context is already canceled, so error should come before execution.
	if _, err := db.QueryContext(ctx, "select pg_sleep(1)"); err == nil {
		t.Fatal("expected error")
	} else if err.Error() != "context canceled" {
		t.Fatalf("unexpected error: %s", err)
	}

	for i := 0; i < contextRaceIterations; i++ {
		func() {
			ctx, cancel := context.WithCancel(context.Background())
			rows, err := db.QueryContext(ctx, "select 1")
			cancel()
			if err != nil {
				t.Fatal(err)
			} else if err := rows.Close(); err != nil && err != driver.ErrBadConn {
				t.Fatal(err)
			}
		}()

		if rows, err := db.Query("select 1"); err != nil {
			t.Fatal(err)
		} else if err := rows.Close(); err != nil {
			t.Fatal(err)
		}
	}
}

// TestIssue617 tests that a failed query in QueryContext doesn't lead to a
// goroutine leak.
func TestIssue617(t *testing.T) {
	db := openTestConn(t)
	defer db.Close()

	const N = 10

	numGoroutineStart := runtime.NumGoroutine()
	for i := 0; i < N; i++ {
		func() {
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()
			_, err := db.QueryContext(ctx, `SELECT * FROM DOESNOTEXIST`)
			pqErr, _ := err.(*Error)
			// Expecting "pq: relation \"doesnotexist\" does not exist" error.
			if err == nil || pqErr == nil || pqErr.Code != "42P01" {
				t.Fatalf("expected undefined table error, got %v", err)
			}
		}()
	}

	// Give time for goroutines to terminate
	delayTime := time.Millisecond * 50
	waitTime := time.Second
	iterations := int(waitTime / delayTime)

	var numGoroutineFinish int
	for i := 0; i < iterations; i++ {
		time.Sleep(delayTime)

		numGoroutineFinish = runtime.NumGoroutine()

		// We use N/2 and not N because the GC and other actors may increase or
		// decrease the number of goroutines.
		if numGoroutineFinish-numGoroutineStart < N/2 {
			return
		}
	}

	t.Errorf("goroutine leak detected, was %d, now %d", numGoroutineStart, numGoroutineFinish)
}

func TestGo18ContextCancelBegin(t *testing.T) {
	db := openTestConn(t)
	defer db.Close()

	ctx, cancel := context.WithCancel(context.Background())
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}

	// Delay execution for just a bit until tx.Exec has begun.
	defer time.AfterFunc(time.Millisecond*10, cancel).Stop()

	// Not canceled until after the exec has started.
	if _, err := tx.Exec("select pg_sleep(1)"); err == nil {
		t.Fatal("expected error")
	} else if err.Error() != "pq: canceling statement due to user request" {
		t.Fatalf("unexpected error: %s", err)
	}

	// Transaction is canceled, so expect an error.
	if _, err := tx.Query("select pg_sleep(1)"); err == nil {
		t.Fatal("expected error")
	} else if err != ErrTxDone {
		t.Fatalf("unexpected error: %s", err)
	}

	// Context is canceled, so cannot begin a transaction.
	if _, err := db.BeginTx(ctx, nil); err == nil {
		t.Fatal("expected error")
	} else if err.Error() != "context canceled" {
		t.Fatalf("unexpected error: %s", err)
	}

	for i := 0; i < contextRaceIterations; i++ {
		func() {
			ctx, cancel := context.WithCancel(context.Background())
			tx, err := db.BeginTx(ctx, nil)
			cancel()
			if err != nil {
				t.Fatal(err)
			} else if err := tx.Rollback(); err != nil &&
				err.Error() != "pq: canceling statement due to user request" &&
				err != ErrTxDone && err != driver.ErrBadConn {
				t.Fatal(err)
			}
		}()

		if tx, err := db.Begin(); err != nil {
			t.Fatal(err)
		} else if err := tx.Rollback(); err != nil {
			t.Fatal(err)
		}
	}
}

func TestTxOptions(t *testing.T) {
	db := openTestConn(t)
	defer db.Close()
	ctx := context.Background()

	tests := []struct {
		level     IsolationLevel
		isolation string
	}{
		{
			level:     LevelDefault,
			isolation: "",
		},
		{
			level:     LevelReadUncommitted,
			isolation: "read uncommitted",
		},
		{
			level:     LevelReadCommitted,
			isolation: "read committed",
		},
		{
			level:     LevelRepeatableRead,
			isolation: "repeatable read",
		},
		{
			level:     LevelSerializable,
			isolation: "serializable",
		},
	}

	for _, test := range tests {
		for _, ro := range []bool{true, false} {
			tx, err := db.BeginTx(ctx, &TxOptions{
				Isolation: test.level,
				ReadOnly:  ro,
			})
			if err != nil {
				t.Fatal(err)
			}

			var isolation string
			err = tx.QueryRow("select current_setting('transaction_isolation')").Scan(&isolation)
			if err != nil {
				t.Fatal(err)
			}

			if test.isolation != "" && isolation != test.isolation {
				t.Errorf("wrong isolation level: %s != %s", isolation, test.isolation)
			}

			var isRO string
			err = tx.QueryRow("select current_setting('transaction_read_only')").Scan(&isRO)
			if err != nil {
				t.Fatal(err)
			}

			if ro != (isRO == "on") {
				t.Errorf("read/[write,only] not set: %t != %s for level %s",
					ro, isRO, test.isolation)
			}

			tx.Rollback()
		}
	}

	_, err := db.BeginTx(ctx, &TxOptions{
		Isolation: LevelLinearizable,
	})
	if err == nil {
		t.Fatal("expected LevelLinearizable to fail")
	}
	if !strings.Contains(err.Error(), "isolation level not supported") {
		t.Errorf("Expected error to mention isolation level, got %q", err)
	}
}