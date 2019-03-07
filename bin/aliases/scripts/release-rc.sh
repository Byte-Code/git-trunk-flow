. $PWD/trunk-flow/aliases/scripts/utils.sh
. $PWD/trunk-flow/aliases/scripts/release.sh "prod" "$(get_last_rc_branch prod)"

#. $PWD/trunk-flow/aliases/scripts/utils.sh
#
#git fetch -tp
#
#PRT_PREFIX=prod
#LRB=$(get_last_rc_branch)
#NOT_IN_LRB_MSG="${NOT_IN_LRB_MSG}You MUST be in '${LRB}' to release it"
#NOT_IN_LRB_MSG="${NOT_IN_LRB_MSG}  (use \"git checkout ${LRB}\" to move on the right branch"
#[ $(git refname) != ${LRB} ] && echo "${NOT_IN_LRB_MSG}" && exit 1
#
#check_upstream ${LRB}
#
#NPT=$(git nexttag ${PRT_PREFIX})
#RELEASE_BRANCH=release-prod
#
#git tag ${NPT}
#git push --no-verify origin ${NPT}
#git push -f origin ${NPT}:${RELEASE_BRANCH} --no-verify
