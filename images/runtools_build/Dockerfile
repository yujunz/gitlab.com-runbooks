FROM golang:alpine AS go-jsonnet

RUN apk add --no-cache bash git && \
    GOPATH=/usr/local go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
    GOPATH=/usr/local go get github.com/google/go-jsonnet/cmd/jsonnet && \
    GOPATH=/usr/local go get github.com/google/go-jsonnet/cmd/jsonnetfmt && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

FROM alpine:latest

COPY --from=nlknguyen/alpine-shellcheck:latest /usr/local/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=peterdavehello/shfmt:latest /bin/shfmt /usr/local/bin/shfmt

COPY --from=go-jsonnet /usr/local/bin/jsonnet /usr/local/bin/jsonnet
COPY --from=go-jsonnet /usr/local/bin/jsonnetfmt /usr/local/bin/jsonnetfmt
COPY --from=go-jsonnet /usr/local/bin/jb /usr/local/bin/jb

RUN apk add --no-cache curl bash git jq alpine-sdk ruby build-base ruby-dev && \
    gem install --no-document json && \
    apk del build-base ruby-dev && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ENTRYPOINT ["/bin/sh", "-c"]
