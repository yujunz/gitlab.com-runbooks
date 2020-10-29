#!/bin/bash

# this script is intended to be run as a scheduled job every 10 minutes (or so)
#
# we will generally have fewer warm nodes than hot nodes. on hot nodes we
# want to spread the write load, and we do this by limiting total_shards_per_node.
# this avoids hotspotting by making colocation of written-to indices less likely.
#
# however, total_shards_per_node becomes a limiting factor when we transition to
# the warm phase, as we now have fewer nodes. in order to address this, we will
# loosen the total_shards_per_node constraint once an index is no longer being
# written to, allowing it to be packed more tightly on warm nodes.

set -euo pipefail

# -n option will not actually apply the settings
dry_run=0
while getopts 'n' opt; do
	case "$opt" in
	n) dry_run=1 ;;
	*)
		echo 'error in command line parsing' >&2
		exit 1
		;;
	esac
done

INDEX_MATCH_DATA="${INDEX_MATCH_DATA:-hot}"
INDEX_MATCH_NUMBER_OF_SHARDS="${INDEX_MATCH_NUMBER_OF_SHARDS:-6}"
INDEX_MATCH_TOTAL_SHARDS_PER_NODE="${INDEX_MATCH_TOTAL_SHARDS_PER_NODE:-2}"
INDEX_APPLY_TOTAL_SHARDS_PER_NODE="${INDEX_APPLY_TOTAL_SHARDS_PER_NODE:-4}"

TMPDIR="$(mktemp -d)"

# fetch indices that are being written to
curl -s "$ELASTICSEARCH_URL/_aliases" |
	jq -r 'to_entries[]|select(.value.aliases[].is_write_index)|.key' |
	sort >"${TMPDIR}/aliases.txt"

# match indices
curl -s "$ELASTICSEARCH_URL/*/_settings" |
	jq -r --arg INDEX_MATCH_DATA "$INDEX_MATCH_DATA" \
		--arg INDEX_MATCH_NUMBER_OF_SHARDS "$INDEX_MATCH_NUMBER_OF_SHARDS" \
		--arg INDEX_MATCH_TOTAL_SHARDS_PER_NODE "$INDEX_MATCH_TOTAL_SHARDS_PER_NODE" \
		'to_entries[]|select(.value.settings.index.routing.allocation.require.data == $INDEX_MATCH_DATA and .value.settings.index.number_of_shards == $INDEX_MATCH_NUMBER_OF_SHARDS and .value.settings.index.routing.allocation.total_shards_per_node == $INDEX_MATCH_TOTAL_SHARDS_PER_NODE)|.key' |
	sort >"${TMPDIR}/indices.txt"

# remove indices that are still being written to
grep -v -x -f "${TMPDIR}/aliases.txt" "${TMPDIR}/indices.txt" >"${TMPDIR}/target_indices.txt" || true

# prepare settings to be applied
echo '{}' |
	jq -c --arg INDEX_APPLY_TOTAL_SHARDS_PER_NODE "$INDEX_APPLY_TOTAL_SHARDS_PER_NODE" \
		'{"index.routing.allocation.total_shards_per_node": $INDEX_APPLY_TOTAL_SHARDS_PER_NODE}' \
		>"${TMPDIR}/settings.txt"

# apply settings to all indices
while IFS= read -r index; do
	echo "applying ${index}"
	if [[ "$dry_run" -eq 0 ]]; then
		curl -XPUT "$ELASTICSEARCH_URL/${index}/_settings" -d "$(cat "${TMPDIR}/settings.txt")"
	fi
done <"${TMPDIR}/target_indices.txt"

rm -rf "$TMPDIR"
