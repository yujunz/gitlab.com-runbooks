#!/bin/bash

$ curl -s "$ELASTICSEARCH_URL/*/_ilm/explain?only_errors=true" | jq -r '.indices[]|select(.step_info.type == "process_cluster_event_timeout_exception")|["curl", "-XPOST", env.ELASTICSEARCH_URL, .index+"/_ilm/retry"]|@sh'
