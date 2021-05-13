.PHONY: create
create:
	cd database-resource \
	&& GOARCH=arm64 CGO_ENABLED=1 go build -buildmode=c-shared -o sql_arm64.so *.go \
	&& GOARCH=amd64 CGO_ENABLED=1 go build -buildmode=c-shared -o sql_amd64.so *.go \

.PHONY: move
move:
	cd database-resource \
	&& mv sql_arm64.so ../src/database/ && mv sql_arm64.h ../src/database/ \
	&& mv sql_amd64.so ../src/database/ && mv sql_amd64.h ../src/database/ \
	&& cd -

.PHONY: all
all: create move
