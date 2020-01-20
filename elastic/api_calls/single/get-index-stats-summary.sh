#!/bin/bash

# This can be used to populate https://docs.google.com/spreadsheets/d/1RN7Ry2pI7iTFURqb0G5zjhNp7xkiPSVG-YsoBOO3TFw.
# The last index for each index alias might be incomplete.
# It only works with pubsub indices in the ES5 cluster, as we rely on their naming pattern which contains the day.

set -eufo pipefail

usage() {
  echo "
  print out pubsub index stats as csv

  Usage: $(basename "$0") [-d|-id]

    -id: summarize stats per index and day
    -i: summarize stats per index
"
  exit 1
}

[ $# -ne 1 ] && usage

opt="$1"

# query stats for all indices, sorted by index name, using bytes as unit
cat_indices() {
  curl -sSL "${ES7_URL_WITH_CREDS}/_cat/indices/?v&s=index&bytes=b"
}

# get all pubsub gprd index alias names
get_index_alias_names() {
  echo "$INDEX_RESPONSE" | grep pubsub | awk '{print $3}' | sed 's/-[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}.*//g' | sort -u
}

# sum the docs.count and pri.store.size by index and day
summarize_index_stats() {

  old_date="none"
  old_name="none"
  doc_count_sum=0
  primary_size_sum=0

  # print header
  echo "index,date,docs.count,pri.store.size"

  while read -r line; do

    index_name=$(echo "$line" | awk '{print $3}' | sed 's/-[0-9]\{4\}\.[0-9]\{2\}\.[0-9]\{2\}.*//g')
    index_date=$(echo "$line" | awk '{print $3}' | sed "s/${index_name}-//" | sed 's/-.*//' | sed 's/\./-/g')
    doc_count=$(echo "$line" | awk '{print $7}')
    primary_size=$(echo "$line" | awk '{print $10}')

    if [ "$old_date" == "none" ]; then old_date=$index_date; fi
    if [ "$old_name" == "none" ]; then old_name=$index_name; fi

    case $opt in
      -id) # summarize for each index alias and day
        if [ "$old_date" != "$index_date" ] || [ "$old_name" != "$index_name" ]; then

          # print out the sum and start counting from 0
          echo "$old_name,$old_date,$doc_count_sum,$primary_size_sum"

          old_date="$index_date"
          old_name="$index_name"
          doc_count_sum=0
          primary_size_sum=0

        fi

        doc_count_sum=$((doc_count_sum + doc_count))
        primary_size_sum=$((primary_size_sum + primary_size))
        ;;

      -i) # summarize for each index alias
        if [ "$old_name" != "$index_name" ]; then

          # print out the sum and start counting from 0
          echo "$old_name,$old_date,$doc_count_sum,$primary_size_sum"

          old_date="$index_date"
          old_name="$index_name"
          doc_count_sum=0
          primary_size_sum=0

        fi

        doc_count_sum=$((doc_count_sum + doc_count))
        primary_size_sum=$((primary_size_sum + primary_size))
        ;;
      *)
        usage
        ;;
    esac

  done <<<"$(echo "$INDEX_RESPONSE" | grep pubsub | grep gprd)"

  echo "$old_name,$old_date,$doc_count_sum,$primary_size_sum"
}

INDEX_RESPONSE="$(cat_indices)"

summarize_index_stats
