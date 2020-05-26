FROM golang:alpine AS go-jsonnet

RUN wget -O go-jsonnet.tar.gz https://api.github.com/repos/google/go-jsonnet/tarball/v0.16.0 && \
  tar -xf go-jsonnet.tar.gz && \
  cd google-go-jsonnet-* && \
  go build ./cmd/jsonnet && \
  go build ./cmd/jsonnetfmt && \
  mv jsonnet jsonnetfmt /usr/local/bin/ && \
  rm -rf go-jsonnet.tar.gz google-go-jsonnet-*

RUN apk add --no-cache bash git && \
    GOPATH=/usr/local go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
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
