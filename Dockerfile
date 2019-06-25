FROM google/cloud-sdk:245.0.0-alpine

ENV PROMETHEUS_VERSION 2.5.0

RUN apk add --no-cache tar ruby && \
   wget -O prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz && \
   mkdir /prometheus && \
   tar -xvf prometheus.tar.gz -C /prometheus --strip-components 1 --wildcards */promtool && \
   rm prometheus.tar.gz

RUN gem install -N yaml-lint
