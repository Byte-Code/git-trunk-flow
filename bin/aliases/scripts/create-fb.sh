. $PWD/trunk-flow/aliases/scripts/utils.sh

# Create a new feature branch, branching off from trunk branch (origin/master)
# Delegate the pushing to remote when the feature is finished using the finish-fb.sh script

TRUNK=master

usage() {
    echo "error: git create-fb <docs|chore|test|refactor|feature|bugfix>/<TP_ID|desc>"
}

FB=
case "${1}" in
    docs/*) ;;
    chore/*) ;;
    test/*) ;;
    refactor/*) ;;
    feature/*) ;;
    bugfix/*) ;;
    *) usage && exit 1;;
esac

fetch_all

FB=${1}

# The --no-track allow us to not set $(git upstream ${TRUNK}) as the remote for this branch
git checkout --no-track -b ${FB} $(git upstream ${TRUNK})
