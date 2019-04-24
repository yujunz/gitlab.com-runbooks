#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

auth=$(echo -n "$PINGDOM_ACCOUNT_EMAIL:$PINGDOM_PASSWORD"|base64)
to=$(gdate -u +"%s" -d "-1 days 00:00")
from=$(gdate -u +"%s" -d "-181 days 00:00")
from2=$(gdate -u +"%s" -d "-300 days 00:00")
from3=$(gdate -u +"%s" -d "-400 days 00:00")
from4=$(gdate -u +"%s" -d "-500 days 00:00")

echo "#Check,Date,Availability"

curl --silent \
  --fail \
  --request GET \
  --url https://api.pingdom.com/api/2.1/checks \
  --header "account-email: $PINGDOM_ACCOUNT_EMAIL" \
  --header "app-key: $PINGDOM_APPKEY" \
  --header "authorization: Basic $auth" | \
 jq -r '.checks[] | select(.hostname == "gitlab.com" and .type == "http")|[.id,.name]|@csv' | \
while read -r check_line; do
  check_id=${check_line%%,*}
  check_name=${check_line##*,}

  curl  --silent \
    --fail \
    --request GET \ \
    --url "https://api.pingdom.com//api/2.1/summary.performance/${check_id}?resolution=day&includeuptime=true&from=${from}&to=${to}" \
    --header "account-email: $PINGDOM_ACCOUNT_EMAIL" \
    --header "app-key: $PINGDOM_APPKEY" \
    --header "authorization: Basic $auth" | \
    jq -r '.summary.days[]|['"${check_name}"', (.starttime| strftime("%Y-%m-%d")), .uptime/86400] | @csv'

  (curl  --silent \
    --fail \
    --request GET \ \
    --url "https://api.pingdom.com//api/2.1/summary.performance/${check_id}?resolution=day&includeuptime=true&from=${from2}&to=${from}" \
    --header "account-email: $PINGDOM_ACCOUNT_EMAIL" \
    --header "app-key: $PINGDOM_APPKEY" \
    --header "authorization: Basic $auth" | \
    jq -r '.summary.days[]|['"${check_name}"', (.starttime| strftime("%Y-%m-%d")), .uptime/86400] | @csv') || true

  (curl  --silent \
    --fail \
    --request GET \ \
    --url "https://api.pingdom.com//api/2.1/summary.performance/${check_id}?resolution=day&includeuptime=true&from=${from3}&to=${from2}" \
    --header "account-email: $PINGDOM_ACCOUNT_EMAIL" \
    --header "app-key: $PINGDOM_APPKEY" \
    --header "authorization: Basic $auth" | \
    jq -r '.summary.days[]|['"${check_name}"', (.starttime| strftime("%Y-%m-%d")), .uptime/86400] | @csv') || true


  (curl  --silent \
    --fail \
    --request GET \ \
    --url "https://api.pingdom.com//api/2.1/summary.performance/${check_id}?resolution=day&includeuptime=true&from=${from4}&to=${from3}" \
    --header "account-email: $PINGDOM_ACCOUNT_EMAIL" \
    --header "app-key: $PINGDOM_APPKEY" \
    --header "authorization: Basic $auth" | \
    jq -r '.summary.days[]|['"${check_name}"', (.starttime| strftime("%Y-%m-%d")), .uptime/86400] | @csv') || true
done



