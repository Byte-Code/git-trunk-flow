. $PWD/trunk-flow/aliases/scripts/utils.sh

git fetch -tp

PRT_PREFIX=${1}
LCB=${2}
PCB=${3}

if [ ! "${LCB}" ]; then
    echo "Nothing to release!"
    if [ "${PCB}" ]; then
        echo "The '${PCB}' was the last released branch" && exit 1
    fi
fi

NOT_IN_LCB_MSG="${NOT_IN_LCB_MSG}You MUST be in '${LCB}' to release it\n"
NOT_IN_LCB_MSG="${NOT_IN_LCB_MSG}  (use \"git checkout ${LCB}\" to move on the right branch"
[ $(git refname) != ${LCB} ] && echo "${NOT_IN_LCB_MSG}" && exit 1

check_upstream ${LCB}
NPT=$(git nexttag ${PRT_PREFIX})
RELEASE_BRANCH=release-${PRT_PREFIX}

echo "Are you sure to release ${LCB} in production?"
read -p "y|n) " DO_RELEASE
case "${DO_RELEASE}" in
    [yY][eE][sS]|[yY])
        git tag ${NPT}
        git push --no-verify origin ${NPT}
        git push -f origin ${NPT}:${RELEASE_BRANCH} --no-verify
        ;;
    *) echo "'${LCB}' has NOT been released!" ;;
esac
