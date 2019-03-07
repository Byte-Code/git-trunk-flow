git fetch -tp

PRT_PREFIX=${1}
LCB=${2}

[ ! ${LCB} ] && echo "Nothing to release!" && exit 1

NOT_IN_LCB_MSG="${NOT_IN_LCB_MSG}You MUST be in '${LCB}' to release it\n"
NOT_IN_LCB_MSG="${NOT_IN_LCB_MSG}  (use \"git checkout ${LCB}\" to move on the right branch"
[ $(git refname) != ${LCB} ] && echo "${NOT_IN_LCB_MSG}" && exit 1

check_upstream ${LCB}

NPT=$(git nexttag ${PRT_PREFIX})
RELEASE_BRANCH=release-prod


read -p "Are you sure to release ${LCB} in production? (y/n)" DO_RELEASE
case "${DO_RELEASE}" in
    [yY][eE][sS]|[yY])
        git tag ${NPT}
        git push --no-verify origin ${NPT}
        git push -f origin ${NPT}:${RELEASE_BRANCH} --no-verify
        ;;
    *)
        echo "Nothing done!"
        ;;
esac
