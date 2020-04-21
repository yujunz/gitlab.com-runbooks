<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Beginner](#beginner)
    - [Create a Visualisation based on a search in Discover](#create-a-visualisation-based-on-a-search-in-discover)
    - [Get percentiles of x requests](#get-percentiles-of-x-requests)
    - [Get time spent in gRPC calls](#get-time-spent-in-grpc-calls)
- [Advanced](#advanced)
    - [Get the number of requests sent from every ip address](#get-the-number-of-requests-sent-from-every-ip-address)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


# Beginner

## Create a Visualisation based on a search in Discover ##

## Get percentiles of x requests ##

## Get time spent in gRPC calls ##

Useful for:
- analyzing which method runs the most often

# Advanced

## Get the number of requests sent from every ip address

Useful for:
- searching for DoS type of behavior

answer:
- Visualization
- data table
- metric: count
- buckets: split rows -> Terms -> json.remote_ip.keyword   (keyword because you want to use an Elastic field that hasn't been split into separate tokens)
