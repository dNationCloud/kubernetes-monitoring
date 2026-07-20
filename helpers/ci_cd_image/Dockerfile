FROM golang:1.26-alpine AS builder

RUN apk update && apk upgrade && \
    apk add --no-cache bash git

# go-jsonnet v0.22.0 (adds std.get etc., required by grafana/grafonnet v13)
RUN git clone https://github.com/google/go-jsonnet.git && \
    cd go-jsonnet && \
    git checkout v0.22.0 && \
    go build ./cmd/jsonnet && \
    go build ./cmd/jsonnetfmt && \
    go build ./cmd/jsonnet-lint

RUN wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /go/yq && \
    chmod +x /go/yq

# grafana/grafonnet v13 (gen/grafonnet-latest) + polystat panel vendored into /vendor
RUN go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.6.0
WORKDIR /go
RUN jb init && \
    jb install github.com/grafana/grafonnet/gen/grafonnet-latest@41e6bfcbe4ef1054298ffff8664f1354c897dd2d && \
    jb install github.com/thelastpickle/grafonnet-polystat-panel@275a48de57afdac0d72219d82863d8ab8bd0e682

FROM alpine:3.20

LABEL Version="2.0.0"
LABEL Vendor="dNation"
LABEL Description="CI/CD jsonnet docker image"

LABEL JsonnetVersion="v0.22.0"
LABEL YqVersion="3.4.1"
LABEL GrafonnetVersion="41e6bfcbe4ef1054298ffff8664f1354c897dd2d"
LABEL GrafonnetPolystatPanelVersion="275a48de57afdac0d72219d82863d8ab8bd0e682"

RUN addgroup -S jsonnet && adduser -S -G jsonnet jsonnet

COPY --from=builder /go/vendor vendor
COPY --from=builder /go/go-jsonnet/jsonnet* /usr/local/bin/
COPY --from=builder /go/bin/jb /usr/local/bin/
COPY --from=builder /go/yq /usr/local/bin/
RUN chmod -R 777 /vendor

USER jsonnet

ENV JSONNET_PATH=/vendor

WORKDIR /src

CMD ["echo", "Please specify command"]
