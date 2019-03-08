. $PWD/trunk-flow/aliases/scripts/utils.sh

TRUNK=master

usage() {
    echo "The current branch doesn't seem to be a valid fb branch.\n"
    echo "A valid fb branch MUST start with docs/|chore/|test/|refactor/|feature/|bugfix/"
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

git fetch

check_upstream

git pull-request ${TRUNK}
