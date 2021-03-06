FROM golang:1.15.2-alpine3.12 AS builder

RUN apk update && apk upgrade && \
    apk add --no-cache bash git

RUN git clone https://github.com/google/go-jsonnet.git && \
    cd go-jsonnet && \
    git reset --hard 31d71aaccda6d98135ecc02acae823ef6e78270c && \
    go build ./cmd/jsonnet && \
    go build ./cmd/jsonnetfmt && \
    go build ./cmd/jsonnet-lint

RUN wget https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -O /go/yq && \
    chmod +x /go/yq

RUN go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
    jb init && \
    jb install https://github.com/grafana/grafonnet-lib/grafonnet@daad85cf3fad3580e58029414630e29956aefe21 && \
    jb install https://github.com/thelastpickle/grafonnet-polystat-panel@275a48de57afdac0d72219d82863d8ab8bd0e682

FROM alpine:3.12

LABEL Version="1.0.3"
LABEL Vendor="dNation"
LABEL Description="CI/CD jsonnet docker image"

LABEL JsonnetVersion="fe2809577220c8c06810e842c074f0f0820e9169"
LABEL YqVersion="3.4.1"
LABEL GrafonnetVersion="daad85cf3fad3580e58029414630e29956aefe21"
LABEL GrafonnetPolystatPanelVersion="275a48de57afdac0d72219d82863d8ab8bd0e682"

RUN addgroup -S jsonnet && adduser -S -G jsonnet jsonnet

COPY --from=builder /go/vendor vendor
COPY --from=builder /go/go-jsonnet/jsonnet* /usr/local/bin/
COPY --from=builder /go/yq /usr/local/bin/
RUN chmod -R 777 /vendor

USER jsonnet

ENV JSONNET_PATH=/vendor

WORKDIR /src

CMD ["echo", "Please specify command"]
