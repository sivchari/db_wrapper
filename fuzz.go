// Go MySQL Driver - A MySQL-Driver for Go's database/.sql package.
//
// Copyright 2020 The Go-MySQL-Driver Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at http://mozilla.org/MPL/2.0/.

// +build gofuzz

package main

import "C"

func Fuzz(data []byte) int {
	uptr := Open(C.CString("mysql"), C.CString(string(data)))
	db := GetDBInstance(uptr)
	if db == nil {
		return 0
	}
	db.Close()
	return 1
}
