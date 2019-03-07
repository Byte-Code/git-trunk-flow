. $PWD/trunk-flow/aliases/scripts/utils.sh

TRUNK=master

usage() {
    echo "The current branch doesn't seem to be a valid fb branch.\n"
    echo "A valid fb branch MUST start with docs/|chore/|test/|style/|refactor/|feat/|fix/"
}

FB=$(git refname)
case "${FB}" in
    docs/*) ;;
    chore/*) ;;
    test/*) ;;
    style/*) ;;
    refactor/*) ;;
    feat/*) ;;
    #retrocompatibility
    feature/*) ;;
    fix/*) ;;
    #retrocompatibility
    bugfix/*) ;;
    feature/*) ;;
    bugfix/*) ;;
    *) usage && exit 1;;
esac

git fetch

check_upstream

git pull-request ${TRUNK}
