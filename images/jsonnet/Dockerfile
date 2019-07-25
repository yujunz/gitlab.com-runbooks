FROM registry.gitlab.com/gitlab-com/runbooks/jsonnet-intermediate:latest

RUN apk add --no-cache curl bash git jq alpine-sdk go ruby build-base ruby-dev && \
    GOPATH=/usr/local go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
    gem install --no-rdoc --no-ri json && \
    apk del build-base ruby-dev && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*
