FROM debian:latest

ENV PROMETHEUS_VERSION 2.0.1

RUN apt-get update && apt-get install -y wget
RUN wget -O prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
RUN mkdir /prometheus
RUN tar -xvf prometheus.tar.gz -C /prometheus --strip-components 1 --wildcards */promtool

