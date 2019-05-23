. $PWD/trunk-flow/aliases/scripts/utils.sh

usage() {
    echo "The current branch doesn't seem to be a valid fb branch.\n"
    echo "A valid fb branch MUST start with docs/|chore/|test/|refactor/|feature/|bugfix/"
}

set_TARGET() {
    UPSTREAM_NOTES=$(get_notes $(git upstream))
    if [ ! ${UPSTREAM_NOTES} ]; then
        TARGET=${TRUNK}
    else
        [ ${UPSTREAM_NOTES} == finish ] && TARGET=finish
    fi
}

FB=$(git refname)
case "${FB}" in
    docs/*) ;;
    chore/*) ;;
    test/*) ;;
    refactor/*) ;;
    feature/*) ;;
    bugfix/*) ;;
    *) usage && exit 1;;
esac

TRUNK=master
fetch_all
set_TARGET
check_upstream ${FB}

UPSTREAM_OBJECT=$(git rev-parse $(get_remote ${FB}))
if [ ${TRUNK} == ${TARGET} ]; then
    git pull-request ${TRUNK} ${FB} & PULL_REQUEST_PID=$!
    wait ${PULL_REQUEST_PID} \
        && overwrite_and_push_notes finish ${UPSTREAM_OBJECT} \
        || exit 1
elif [ ${TARGET} == finish ]; then
    handle_finish ${TRUNK} ${FB}
fi
