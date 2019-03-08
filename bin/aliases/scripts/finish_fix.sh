. $PWD/trunk-flow/aliases/scripts/utils.sh

#FIX_TYPES: hc-fix, hc-inhibit, rc-fix, rc-inhibit
FIX_TYPE=$1

set_TARGET() {
    PREV_TARGET=${1}
    UPSTREAM_NOTES=$(get_notes $(git upstream))

    if [ ${UPSTREAM_NOTES} ]; then
        [ ${UPSTREAM_NOTES} ] && [[ ${UPSTREAM_NOTES} == ${TRUNK} ]] && TARGET=${TRUNK}
        [ ${UPSTREAM_NOTES} ] && [[ ${UPSTREAM_NOTES} == err_* ]] && TARGET=${UPSTREAM_NOTES}
        [ ${UPSTREAM_NOTES} ] && [[ ${UPSTREAM_NOTES} == finish ]] && TARGET=finish
        if [ ! ${TARGET} ]; then
            # TODO test better this case
            ORIGIN_PREV_TARGET=$(git upstream ${PREV_TARGET})
            CONTAINER=$(git branch --list --remote --contains $(git rev-parse HEAD) ${ORIGIN_PREV_TARGET})
            CONTAINER=$(echo ${CONTAINER}) # remove leading and trailing whitespaces
            if [ ! ${CONTAINER} ]; then
                echo "It seems that your pull-request to '${PREV_TARGET}' has not yet been merged" && exit 1
            elif [ ${CONTAINER} == ${ORIGIN_PREV_TARGET} ]; then
                TARGET=${TRUNK}
            fi
        fi
    fi
    # the very first time that we call finish-rc-fix.sh
    [ ! ${TARGET} ] && TARGET=${PREV_TARGET}
}

TRUNK=master

fetch_all

FIX=$(git refname)

case "${FIX_TYPE}" in
    hc-fix) [[ ${FIX} != hotfix* ]] && echo "The current branch doesn't seem to be an 'hotfix' branch" && exit 1;;
#    hc-inhibit) ;;
    rc-fix) [[ ${FIX} != *@* ]] && echo "The current branch doesn't seem to be a 'rc-fix' branch" && exit 1;;
    rc-inhibit) [[ ${FIX} != *#* ]] && echo "The current branch doesn't seem to be a 'rc-inhibit' branch" && exit 1;;
esac

case "${FIX_TYPE}" in
    hc-fix)
        LHB=$(get_last_hc_branch prod)
        LRB=$(get_last_rc_branch prod)
        set_TARGET ${LHB} ;;
    rc-fix|rc-inhibit)
        #TODO Test if is sufficient only the next line or should we consider to pass
        #TODO prod to get_last_rc_branch() and exit if ! ${LRB}
        LRB=$(get_last_rc_branch)
#        LRB=$(get_last_rc_branch prod)
#        [ ! ${LRB} ] && echo "There is no rc-branch ongoing!!!" && exit 1
        set_TARGET ${LRB} ;;
esac

check_upstream ${FIX}

merge_to_target() {
    BASE=${1}
    COMPARE=${2}
    NOTES=${3}
    OBJECT=${4}
    git pull-request ${BASE} ${COMPARE}
    overwrite_and_push_notes ${NOTES} ${OBJECT}
}

push_and_merge() {
    git push -f origin ${FIX} & PUSH_PID=$!
    wait ${PUSH_PID} \
        && merge_to_target ${TRUNK} ${FIX} finish \
        || overwrite_and_push_notes err_push ${UPSTREAM_OBJECT}
}

UPSTREAM_OBJECT=$(git rev-parse $(git upstream))
if [ ${LHB} ] && [ ${TARGET} == ${LHB} ]; then
    echo "Trying to create a pull request in '${LHB}'"
    MERGE_BASE=$(git merge-base ${FIX} ${LHB})
    merge_to_target ${LHB} ${FIX} ${MERGE_BASE} ${FIX}
elif [ ${LRB} ] && [ ${TARGET} == ${LRB} ]; then
    echo "Trying to create a pull request in '${LRB}'"
    if [ ${FIX_TYPE} == "rc-inhibit" ]; then
        git pull-request ${LRB} ${FIX}
    else
        MERGE_BASE=$(git merge-base ${FIX} ${LRB})
        merge_to_target ${LRB} ${FIX} ${MERGE_BASE} ${FIX}
    fi
elif [ ${TARGET} == ${TRUNK} ]; then
    echo "Trying to create a pull request in '${TRUNK}'"
	MERGE_BASE=$(get_notes ${UPSTREAM_OBJECT})
    echo "git rebase --onto $(git upstream ${TRUNK}) ${MERGE_BASE} ${FIX}"
	git rebase --onto $(git upstream ${TRUNK}) ${MERGE_BASE} ${FIX}
	RET=$(echo $?)

    # TODO
    # 1. Stress test a broken rebase!
    # 2. Stress test a broken push?
	if [ ${RET} == "0" ]; then
        push_and_merge
	else
    	overwrite_and_push_notes err_rebase ${UPSTREAM_OBJECT}
    	echo
		echo "After having solved the rebase you MUST pull request ${FIX} on master"
        echo
	fi
elif [[ ${TARGET} == *err_* ]]; then
    push_and_merge
elif [ ${TARGET} == finish ]; then
    if [ $(git branch --list --remote --contains $(git rev-parse HEAD) $(git upstream ${TRUNK})) ]; then
        echo "Everything done"
        git checkout ${TRUNK}
        git pull origin ${TRUNK}
        git branch -D ${FIX}
        git push origin --delete --no-verify ${FIX}
    else
        echo "It seems that your pull-request to '${TRUNK}' has not yet been merged"
    fi
fi
