[ ${#GITLAB_CDPATH_ROOT[@]} -eq 0 ] && return
for CDPATH_ROOT in ${GITLAB_CDPATH_ROOT[@]}; do
  for CDPATH_GROUP in $(ls $CDPATH_ROOT); do
    NEW_CD_PATH="${CDPATH_ROOT}/${CDPATH_GROUP}"
    [ -z "${var+CDPATH}" ] && NEW_CD_PATH="${CDPATH}:${NEW_CD_PATH}"
    export CDPATH="${NEW_CD_PATH}"
  done
done
unset CDPATH_GROUP
unset CDPATH_ROOT
