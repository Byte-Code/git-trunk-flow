. $PWD/trunk-flow/aliases/scripts/utils.sh

git fetch -tp

PRT_PREFIX=prod

RC_BRANCH=$(get_last_rc_branch ${PRT_PREFIX})
HC_BRANCH=$(get_last_hc_branch ${PRT_PREFIX})
C_BRANCHES="${RC_BRANCH} ${HC_BRANCH}"

if [ "${C_BRANCHES}" ]; then
    echo "Please choose *c-branch to release:"
    select LCB in $C_BRANCHES
    do
        if [[ "${LCB}" == "" ]]; then
            echo "$REPLY is not a valid choose"
            continue
        fi
        break
    done
fi

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
