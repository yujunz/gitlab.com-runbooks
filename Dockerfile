FROM alpine:3.7

ENV PROMETHEUS_VERSION 2.1.0

RUN apk add --no-cache wget tar && \
   wget -O prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz && \
   mkdir /prometheus && \
   tar -xvf prometheus.tar.gz -C /prometheus --strip-components 1 --wildcards */promtool && \
   rm prometheus.tar.gz

