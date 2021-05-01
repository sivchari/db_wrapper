FROM golang:1.16.3-alpine
RUN apk update && \
    apk upgrade --no-cache
RUN apk add --no-cache \
      git \
      gcc

WORKDIR /go/src