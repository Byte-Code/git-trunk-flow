. $PWD/trunk-flow/aliases/scripts/utils.sh

git fetch -tp

PRT_PREFIX=${1}
LCB=${2}

if [ ! "${LCB}" ]; then
    echo "Nothing to release!"
fi

NOT_IN_LCB_MSG="${NOT_IN_LCB_MSG}You MUST be in '${LCB}' to release it\n"
NOT_IN_LCB_MSG="${NOT_IN_LCB_MSG}  (use \"git checkout ${LCB}\" to move on the right branch"
[ $(git refname) != ${LCB} ] && echo "${NOT_IN_LCB_MSG}" && exit 1

check_upstream ${LCB}
NPT=$(git nexttag ${PRT_PREFIX})
RELEASE_BRANCH=release-${PRT_PREFIX}

echo "Are you sure to push '${LCB}' to '${RELEASE_BRANCH}'?"
read -p "y|n) " DO_RELEASE
case "${DO_RELEASE}" in
    [yY][eE][sS]|[yY])
        echo "git tag ${NPT}"
        git tag ${NPT}
        echo "git push --no-verify origin ${NPT}"
        git push --no-verify origin ${NPT}
        echo "git push -f origin ${NPT}:${RELEASE_BRANCH} --no-verify"
        git push -f origin ${NPT}:${RELEASE_BRANCH} --no-verify
        ;;
    *) echo "aborting!" ;;
esac
