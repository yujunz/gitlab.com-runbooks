#!/bin/bash

### Pre flight checks
DATE_CMD="date"
if ! ${DATE_CMD} --version 2>/dev/null | grep -q GNU; then
  DATE_CMD="gdate"
  if ! hash gdate >/dev/null; then
    echo "GNU date required as date or gdate command" 1>&2
    exit 1
  fi
fi
if ! hash gsutil >/dev/null; then
  echo "gsutil required" 1>&2
  exit 1
fi
if ! hash bc >/dev/null; then
  echo "bc required" 1>&2
  exit 1
fi
if ! hash jq >/dev/null; then
  echo "jq required" 1>&2
  exit 1
fi

help() {
  cat <<EOF 1>&2
Usage: $0 -e <gprd,gstg,ops> [-d <ISO8601 date>=current date] [-t <http,spectrum>=http] [-b <lookback in minutes (multiple of 5)>]

Note, if -d is set to present time (and up to 10 minutes in the past) it might not contain all logs yet.
EOF
}

while getopts "e:b:d:t:h" OPTION; do
  case $OPTION in
    e)
      case $OPTARG in
        gprd)
          ENVIRONMENT="${OPTARG}"
          PROJECT="gitlab-production"
          ;;
        gstg)
          ENVIRONMENT="${OPTARG}"
          PROJECT="gitlab-staging-1"
          ;;
        ops)
          ENVIRONMENT="${OPTARG}"
          PROJECT="gitlab-ops"
          ;;
        *)
          echo "Invalid environment. Valid: gprd, gstg, ops" 1>&2
          exit 1
          ;;
      esac
      ;;
    d)
      if $DATE_CMD --date "${OPTARG}" &>/dev/null; then
        DATE="${OPTARG}"
      else
        echo "Invalid time. Valid: HH:MM (24h time)" 1>&2
      fi
      ;;
    t)
      case $OPTARG in
        http)
          TYPE="http"
          ;;
        spectrum)
          TYPE="spectrum"
          ;;
      esac
      ;;
    b)
      if [ -n "${OPTARG}" ] && [ "${OPTARG}" -eq "${OPTARG}" ] 2>/dev/null; then
        LOOKBACK=$(echo "${OPTARG} - ${OPTARG}%5" | bc)
      else
        echo "Invalid lookback. Valid: time in minutes (5 minute increments)" 1>&2
      fi
      ;;
    h)
      help
      exit 0
      ;;
    *)
      echo "Incorrect options provided" 1>&2
      help
      exit 1
      ;;
  esac
done

if [ -z "${ENVIRONMENT}" ]; then
  echo "No env provided (-e)" 1>&2
  help
  exit 1
fi
if [ -z "${DATE}" ]; then
  DATE=$(${DATE_CMD} --utc)
fi

if [ -z "${LOOKBACK}" ]; then
  LOOKBACK=0
fi
if [ -z "${TYPE}" ]; then
  TYPE=http
fi

# Round date to 5 minutes (as CF buckets in 5min intervals)
DATE="$(echo "$(${DATE_CMD} --utc --date "${DATE}" +%s) - ($(${DATE_CMD} --utc --date "${DATE}" +%s)%300)" | bc)"

echo "Env: ${ENVIRONMENT}, Project: ${PROJECT}" 1>&2
echo "Showing '${TYPE}'-logs at $($DATE_CMD --utc --iso-8601=minutes --date "@${DATE}") UTC, looking back ${LOOKBACK} minutes" 1>&2

OFFSET=0
URLS=""
while [ $OFFSET -le ${LOOKBACK} ]; do
  OFFSET_DATE=$(echo "${DATE} - (${OFFSET} * 60)" | bc)
  QUERY_DATE=$($DATE_CMD --utc --iso-8601=minutes --date "@${OFFSET_DATE}" | cut -d+ -f1 | sed 's/[-:]//g')
  QUERY_DAY=$(echo "$QUERY_DATE" | cut -dT -f1)
  URLS="${URLS} gs://gitlab-${ENVIRONMENT}-cloudflare-logpush/${TYPE}/${QUERY_DAY}/${QUERY_DATE}00Z*"
  ((OFFSET = OFFSET + 5))
done
echo "Searching log files..." 1>&2
# shellcheck disable=SC2086
FILES=$(gsutil ls -p "${PROJECT}" ${URLS} 2>/dev/null | sort -V | xargs)
echo "Piping content..." 1>&2
# shellcheck disable=SC2086
gsutil cat $FILES | gunzip
