# Create a new feature branch, branching off from trunk branch (origin/master)
# Delegate the pushing to remote when the feature is finished using the finish-fb.sh script

TRUNK=master

git fetch

usage() {
    echo "error: git create-fb <docs|chore|test|style|refactor|feat|fix> <TP_ID|aCamelCaseDesc>"
}

[ ! ${2} ] && usage && exit 1

FB_NAME=
case "${1}" in
    docs) FB_NAME="${1}/${2}";;
    chore) FB_NAME="${1}/${2}";;
    test) FB_NAME="${1}/${2}";;
    style) FB_NAME="${1}/${2}";;
    refactor) FB_NAME="${1}/${2}";;
    feat) FB_NAME="${1}/${2}";;
    fix) FB_NAME="${1}/${2}";;
    *) usage && exit 1;;
esac

# The --no-track allow us to not set $(git upstream ${TRUNK}) as the remote for this branch
git checkout --no-track -b ${FB_NAME} $(git upstream ${TRUNK})
