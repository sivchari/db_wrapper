## mac
## GOARCH=arm64 CGO_ENABLED=1 go build -buildmode=c-shared -o sql_arm64.so *.go
## GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared -o sql_amd64.so *.go

## linux
## go get golang.org/dl/go1.16
## go1.16 download
## CGO_ENABLED=1 go1.16 build -buildmode=c-shared -o sql_linux_amd64.so *.go

## windows
## apt -y update
## apt -y install gcc-multilib
## apt -y install gcc-mingw-w64
## apt -y install binutils-mingw-w64
## GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CXX=x86_64-w64-mingw32-g++ CC=x86_64-w64-mingw32-gcc go build -buildmode=c-shared -o sql_windows_amd64.dll *.go
