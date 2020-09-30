FROM golang:1.15.2-alpine3.12 AS builder

RUN apk update && apk upgrade && \
    apk add --no-cache bash git

RUN git clone https://github.com/google/go-jsonnet.git && \
    cd go-jsonnet && \
    go build ./cmd/jsonnet && \
    go build ./cmd/jsonnetfmt && \
    go build ./cmd/jsonnet-lint

RUN go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
    jb init && \
    jb install https://github.com/grafana/grafonnet-lib/grafonnet && \
    jb install https://github.com/bitnami-labs/kube-libsonnet && \
    jb install https://github.com/thelastpickle/grafonnet-polystat-panel

FROM alpine:3.12

LABEL Vendor="dNation"
LABEL Description="CI/CD jsonnet docker image"

RUN addgroup -S jsonnet && adduser -S -G jsonnet jsonnet

COPY --from=builder /go/vendor vendor
COPY --from=builder /go/go-jsonnet/jsonnet* /usr/local/bin/
RUN chmod -R 777 /vendor

USER jsonnet

ENV JSONNET_PATH=/vendor

WORKDIR /src

CMD ["echo", "Please specify command"]
