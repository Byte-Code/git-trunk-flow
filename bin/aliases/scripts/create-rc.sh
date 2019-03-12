. $PWD/trunk-flow/aliases/scripts/utils.sh

TRUNK=master
NOT_IN_TRUNK_MSG="${NOT_IN_TRUNK_MSG}You MUST be in '${TRUNK}' to create a new rc branch\n"
NOT_IN_TRUNK_MSG="${NOT_IN_TRUNK_MSG}  (use \"git checkout ${TRUNK}\" to move on the right branch"
[ $(git refname) != ${TRUNK} ] && echo "${NOT_IN_TRUNK_MSG}" && exit 1

RCT_PREFIX=rc
PRT_PREFIX=prod

git fetch -tp

check_upstream

LRB=$(get_last_rc_branch)

if [[ $(git cherry $(git lasttag ${PRT_PREFIX}) $(get_remote ${LRB})) ]]; then
    # Check that the last rc-branch has some commits not yet released on the
    # last production tag. If that is the case...
    echo "There is already \"${LRB}\" ongoing"
else
    # If last rc-branch is completely contained into last production tag
    # check that there are some commits to release and then create
    # a new rc-branch
    if [ "$(git cherry $(git lasttag ${PRT_PREFIX}) $(get_remote ${TRUNK}))" ]; then
        fetch_notes
        FEATURE_INHIBIT=$(get_features_inhibit $(git list-fb script))
        NRT=$(git nexttag ${RCT_PREFIX})
        NRB=$(create_branch_from_tag ${NRT})

        FEATURES=$(git list-fb create ${FEATURE_INHIBIT})
        # Create tag
        git tag ${NRT}
        # Push tag
        git push --no-verify origin ${NRT}
        # Add notes to tag
        git notes add -f -m "${FEATURES}" "${NRT}"
        # Push notes
        git push --no-verify origin refs/notes/commits
        # Create branch and check it out
        git checkout --no-track -b ${NRB} $(git upstream ${TRUNK})
        # Push branch
        git push --no-verify --set-upstream origin ${NRB}
    else
        echo "Nothing to add"
    fi
fi
