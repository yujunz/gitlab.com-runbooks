ARG  CI_REGISTRY_IMAGE=registry.gitlab.com/gitlab-com/runbooks
FROM ${CI_REGISTRY_IMAGE}/runtools_build-intermediate:latest

COPY --from=nlknguyen/alpine-shellcheck:latest /usr/local/bin/shellcheck /usr/local/bin/shellcheck
COPY --from=peterdavehello/shfmt:latest /bin/shfmt /usr/local/bin/shfmt

RUN apk add --no-cache curl bash git jq alpine-sdk go ruby build-base ruby-dev && \
    GOPATH=/usr/local go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb && \
    gem install --no-rdoc --no-ri json && \
    apk del build-base ruby-dev && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

ENTRYPOINT ["/bin/sh", "-c"]
