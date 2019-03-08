get_remote() {
    BRANCH=$1
    [ ! ${BRANCH} ] && echo "You must provide the branch to check the remote for" && exit 1
    echo $(git for-each-ref --format="%(refname:lstrip=2)" "refs/remotes/*/${BRANCH}")
}

create_branch_from_tag() {
    TAG=$1
    # If not provided, the prefix will be automatically deduced from the provided tag
    # e.g. my_tag_prefix-v* -> TAG_PREFIX=my_tag_prefix
    TAG_PREFIX=$2

    [ ! ${TAG} ] && echo "You must provide the tag from which create the branch" && exit 1
    [ ! ${TAG_PREFIX} ] && TAG_PREFIX=$(cut -d '-' -f1 <<< "${TAG}")
    TAG_VERSION=$(cut -d '-' -f2 <<< "${TAG}")
    BRANCH_PREFIX="${TAG_PREFIX}-branch"

    echo "${BRANCH_PREFIX}-${TAG_VERSION}"
}

get_last_rc_branch() {
    # Passing the production tag prefix (PRT_PREFIX) we want to know
    # the last rc-branch only if not already released.
    # This is useful to know if we have to close an hotfix also on
    # the rc-branch or we can just close it on master
    # If not provided this function just create an rc-branch name
    # starting from last RCT_PREFIX tag
    PRT_PREFIX=$1
    RCT_PREFIX=rc

    LRT=$(git lasttag ${RCT_PREFIX})
    LRB=$(create_branch_from_tag ${LRT})

    if [ ${PRT_PREFIX} ]; then
        # Return the LRB only if not already released
        [ $(git cherry $(git lasttag ${PRT_PREFIX}) $(git upstream ${LRB})) ] && echo "${LRB}"
    else
        # Just create the rc-branch name starting from last PRT_PREFIX's version
        echo "${LRB}"
    fi
}

get_last_hc_branch() {
    PRT_PREFIX=$1
    [ ! ${PRT_PREFIX} ] && echo "You must provide the PRT_PREFIX to get the hc-branch" && exit 1
    FORCE=$2
    HCT_PREFIX=hc
    LPT=$(git lasttag ${PRT_PREFIX})
    LHB=$(create_branch_from_tag ${LPT} hc)

    if [ ${FORCE} ]; then
        # Just create the hc-branch name starting from last PRT_PREFIX's version
        echo ${LHB}
    else
        if [ $(git ls-remote --heads origin ${LHB}) ]; then
            echo ${LHB}
        fi
    fi
}

#get_next_hc_branch() {
#    PRT_PREFIX=$1
#    HCT_PREFIX=hc
#    LPT=$(git lasttag ${PRT_PREFIX})
#    LHB=$(create_branch_from_tag ${LPT} hc)
#
#    echo ${LHB}
#}
#
#get_prev_hc_branch() {
#    PRT_PREFIX=$1
#    HCT_PREFIX=hc
#    LPT=$(git lasttag ${PRT_PREFIX})
#    LHB=$(create_branch_from_tag ${LPT} hc)
#
#    echo ${LHB}
#}

sleep_n() {
    [ ${1} ] && N=${1} || N=1
    sleep ${N}
    exit 1
}

sub_foo(){
    echo "Hello $1 $2"
}

foo() {
    sub_foo "$@"
}

# git notes START
fetch_notes() {
    git fetch origin refs/notes/commits:refs/notes/commits
}

push_notes() {
    git push origin refs/notes/commits --no-verify
}

get_notes() {
    OBJECT=$1
    git notes show ${OBJECT} 2>/dev/null
}

overwrite_notes() {
    NOTES=$1
    OBJECT=$2
    git notes add -f -m ${NOTES} ${OBJECT}
}

overwrite_and_push_notes() {
    overwrite_notes "$@"
    push_notes
}

remove_and_push_notes() {
    OBJECT=$1
    git notes remove ${OBJECT}
    push_notes
}
# git notes END

fetch_all() {
    git fetch -tp
    fetch_notes
}

format_behind_msg() {
    UPSTREAM=${1}
    NEW_BRANCH=${2}
    BEHIND_MSG=
    BEHIND_MSG="${BEHIND_MSG}You MUST be up to date with '${UPSTREAM}' to create a new ${NEW_BRANCH}.\n"
    BEHIND_MSG="${BEHIND_MSG}To align your local with the remote\n\n"
    BEHIND_MSG="${BEHIND_MSG}  (use \"git pull --rebase\")\n"
    echo "${BEHIND_MSG}"
}

#create_branch_from_tag() {
#    TAG=$1
#    # If TAG_VERSION provided, this version will be used.
#    # In this case you could provide also only the TAG prefix (without the -v* part)
#    TAG_VERSION=$2
#
#    [ ! ${TAG} ] && echo "You must provide the tag from which create the branch" && exit 1
#
#    TAG_PREFIX=$(cut -d '-' -f1 <<< "${TAG}")
#    [ ! ${TAG_VERSION} ] && TAG_VERSION=$(cut -d '-' -f2 <<< "${TAG}")
#    BRANCH_PREFIX="${TAG_PREFIX}-branch"
#
#    echo "${BRANCH_PREFIX}-${TAG_VERSION}"
#}

get_features_inhibit() {
    FEATURES=${1}
    FEATURES_INHIBIT=
    IFS=','
    for FB in ${FEATURES}
    do
        # Filter only inhibit
        if [[ ${FB} == *#* ]]; then
            FB=$(cut -d '#' -f1 <<< "${FB}")
            if [ "${FEATURES_INHIBIT}" ]; then
                # avoid duplicates
                [[ ${FEATURES_INHIBIT} != *"${FB}"* ]] && FEATURES_INHIBIT="${FEATURES_INHIBIT},${FB}"
            else
                FEATURES_INHIBIT="${FB}"
            fi
        fi
    done
    echo "${FEATURES_INHIBIT}"
}

# Check that COMPARE_BRANCH contains the last commit of remote BASE_BRANCH
is_mergeable() {
	BASE_BRANCH=$1
	COMPARE_BRANCH=$2
	echo $(git branch --contains $(git upstream ${BASE_BRANCH}) ${COMPARE_BRANCH})
}

check_upstream() {
    TOPIC=${1}
    [ ! ${TOPIC} ] && TOPIC=$(git refname)
    if [[ $(git behind) ]]; then
        if [[ $(git ahead) ]]; then
            DIVERGED_MSG=
            DIVERGED_MSG="${DIVERGED_MSG}Your branch and '$(git upstream)' have diverged,\n\n"
            DIVERGED_MSG="${DIVERGED_MSG}1) if you have just rebased this branch, it's normal\n"
            DIVERGED_MSG="${DIVERGED_MSG}   (use \"git push -f origin ${TOPIC}\" to update the remote branch)\n"
            DIVERGED_MSG="${DIVERGED_MSG}2) if not in the previous case, someone may have pushed just a moment ago\n"
            DIVERGED_MSG="${DIVERGED_MSG}   (use \"git pull --rebase\" to update your local branch)\n"
            DIVERGED_MSG="${DIVERGED_MSG}   (use \"git push origin ${TOPIC}\" to update the remote branch with your changes)\n\n"
            DIVERGED_MSG="${DIVERGED_MSG}When ready, re-run this command"
            echo "${DIVERGED_MSG}" && exit 1
        else
            BEHIND_MSG=
            BEHIND_MSG="${BEHIND_MSG}Your branch is behind '$(git upstream)'\n"
            BEHIND_MSG="${BEHIND_MSG} (use \"git pull\" to update your local branch)\n\n"
            BEHIND_MSG="${BEHIND_MSG}When ready, re-run this command"
            echo "${BEHIND_MSG}" && exit 1
        fi
    elif [[ $(git ahead) ]]; then
        AHEAD_MSG=
        AHEAD_MSG="${AHEAD_MSG}Your branch is ahead of '$(git upstream)'\n"
        AHEAD_MSG="${AHEAD_MSG} (use \"git push origin ${TOPIC}\" to update the remote branch with your changes)\n\n"
        AHEAD_MSG="${AHEAD_MSG}When ready, re-run this command"
        echo "${AHEAD_MSG}" && exit 1
    else
        NO_UPSTREAM_MSG=
        NO_UPSTREAM_MSG="${NO_UPSTREAM_MSG}fatal: The current branch '${TOPIC}' has no upstream branch.\n\n"
        NO_UPSTREAM_MSG="${NO_UPSTREAM_MSG}To push the current branch and set the remote as upstream\n\n"
        NO_UPSTREAM_MSG="${NO_UPSTREAM_MSG} (use \"git push --set-upstream origin ${TOPIC})\n\n"
        NO_UPSTREAM_MSG="${NO_UPSTREAM_MSG}When ready, re-run this command"
        [[ ! $(git upstream ${TOPIC}) ]] && echo "${NO_UPSTREAM_MSG}" && exit 1
    fi
}
