. $PWD/trunk-flow/aliases/scripts/utils.sh

git fetch -tp

RELEASE_BRANCH=${1}
TRUNK=master

do_push(){
    RELEASE_BRANCH=$1
    MSG="${2}"
    [ ! "${MSG}" ] && MSG="Are you sure to push the current HEAD to '${RELEASE_BRANCH}'?"
    echo "${MSG}"
    read -p "y|n) " DO_RELEASE
    case "${DO_RELEASE}" in
        [yY][eE][sS]|[yY])
            echo "git push -f origin HEAD:${RELEASE_BRANCH} --no-verify"
            git push -f origin HEAD:${RELEASE_BRANCH} --no-verify
            ;;
        *) echo "aborting!" ;;
    esac
}

if [ ! "${RELEASE_BRANCH}" ]; then
    echo "You must specify a remote branch where to release the current HEAD!" && exit 1
fi

if  [ ! "$(git branch --contains $(git rev-parse $(git upstream ${TRUNK})) $(git refname))" ]; then
    echo "You must rebase this branch with '$(git upstream ${TRUNK})'"
    echo "   (use \"git rebase -p $(git upstream ${TRUNK})\")\n"
    echo "When ready, re-run this command"
else
    if [ ! "$(git cherry $(git upstream ${TRUNK}) $(get_remote ${RELEASE_BRANCH}))" ]; then
        do_push ${RELEASE_BRANCH}
    else
        echo "It seems that '$(get_remote ${RELEASE_BRANCH})' is not aligned with '$(git upstream ${TRUNK})'"
        echo "You MUST FIX this before continue with the release, or\n"
        echo "    IF YOU KNOW WHAT ARE DOING...\n"
        echo "you can OVERWRITE '$(get_remote ${RELEASE_BRANCH})' with the current HEAD\n"
        MSG="Are you sure to OVERWRITE '$(get_remote ${RELEASE_BRANCH})' with the current HEAD?"
        MSG="\033[1;31m${MSG}\033[0m"
        do_push ${RELEASE_BRANCH} "${MSG}"
    fi
fi
