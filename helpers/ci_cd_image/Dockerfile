FROM golang:1.15.2-alpine3.12 AS builder

RUN apk update && apk upgrade && \
    apk add --no-cache bash git

RUN git clone https://github.com/google/go-jsonnet.git && \
    cd go-jsonnet && \
    git reset --hard 6967a297218e9fda789ae8352e09c3316c292aa4 && \
    go build ./cmd/jsonnet && \
    go build ./cmd/jsonnetfmt && \
    go build ./cmd/jsonnet-lint

RUN go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
    jb init && \
    jb install https://github.com/grafana/grafonnet-lib/grafonnet@ff69572caf78c3163980d0d723c85a722eab73d9 && \
    jb install https://github.com/bitnami-labs/kube-libsonnet@2c48e8e3fb40e38461ba27b05a290877c1e39cec && \
    jb install https://github.com/thelastpickle/grafonnet-polystat-panel@ba245893b700f4021dceb45c9eecf45de57861aa

FROM alpine:3.12

LABEL Vendor="dNation"
LABEL Description="CI/CD jsonnet docker image"
LABEL JsonnetCommit="6967a297218e9fda789ae8352e09c3316c292aa4"

LABEL GrafonnetCommit="ff69572caf78c3163980d0d723c85a722eab73d9"
LABEL KubeLibsonnetCommit="2c48e8e3fb40e38461ba27b05a290877c1e39cec"
LABEL GrafonnetPolystatPanelCommit="ba245893b700f4021dceb45c9eecf45de57861aa"

RUN addgroup -S jsonnet && adduser -S -G jsonnet jsonnet

COPY --from=builder /go/vendor vendor
COPY --from=builder /go/go-jsonnet/jsonnet* /usr/local/bin/
RUN chmod -R 777 /vendor

USER jsonnet

ENV JSONNET_PATH=/vendor

WORKDIR /src

CMD ["echo", "Please specify command"]
