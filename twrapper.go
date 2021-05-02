package main

import "C"

func convertStringFromGoToC(str1, str2 string) (cStr1 *C.char, cStr2 *C.char) {
	cStr1, cStr2 = C.CString(str1), C.CString(str2)
	return
}
