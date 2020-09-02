#!/bin/bash

TARGET_GIT_DIR=$1
[[ -z "$TARGET_GIT_DIR" ]] && echo "Usage: $0 [git_dir]" && exit 1

for PACK_PID in $( pgrep -f 'git pack-objects .*--stdout' )
do
    echo "Examining PID $PACK_PID"
    ps uwf -p $PACK_PID | cat

    PARENT_PID=$( ps -p $PACK_PID -o ppid= )
    ps -p $PARENT_PID -o args= | grep -q 'git .*upload-pack' || continue

    echo "This PID is a child of upload-pack:"
    ps uwf -p $PARENT_PID | cat

    echo "Checking repo dir"
    PID_CURRENT_DIR=$( sudo ls -l /proc/$PACK_PID/cwd | perl -pe 's/.* -> //' )
    echo "$PID_CURRENT_DIR" | grep -q "$TARGET_GIT_DIR" || continue
    echo "PID current dir matches target git dir"

    echo "Killing git-pack-objects pid: $PACK_PID"
    (
        echo "Killing pid $PACK_PID: $( ps uwf -p $PACK_PID | grep -v 'PID' )"
    ) 1>&2 
    sudo kill $PACK_PID
done
