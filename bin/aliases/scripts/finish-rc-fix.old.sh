. $PWD/trunk-flow/aliases/scripts/aliases/scripts/utils.sh

#fake 5 gh
#echo "OK" || echo "KO"

#good(){
#echo "$1 :)"
#echo "$2 :)"
#echo "$3 :)"
#}
#
#bad(){
#echo ":( $1"
#echo ":( $2"
#echo ":( $3"
#}
#
#sleep_n 1 &
#PID=$!
#echo "IMMEDIATE ${PID}"
#wait ${PID} \
#&& good a b c \
#|| bad x y z
#echo "FINALLY"
#
#exit

set_TARGET() {
    LRB=${1}
    UPSTREAM_NOTES=$(get_notes $(git upstream))

    if [ ${UPSTREAM_NOTES} ]; then
        [ ${UPSTREAM_NOTES} ] && [[ ${UPSTREAM_NOTES} == ${TRUNK} ]] && TARGET=${TRUNK}
        [ ${UPSTREAM_NOTES} ] && [[ ${UPSTREAM_NOTES} == err_* ]] && TARGET=${UPSTREAM_NOTES}
        [ ${UPSTREAM_NOTES} ] && [[ ${UPSTREAM_NOTES} == finish ]] && TARGET=finish
        if [ ! ${TARGET} ]; then
            # the second time we call finish-rc-fix.sh
            ORIGIN_LRB=$(git upstream ${LRB})
            CONTAINER=$(git branch --list --remote --contains $(git rev-parse HEAD) ${ORIGIN_LRB})
            CONTAINER=$(echo ${CONTAINER}) # remove leading and trailing whitespaces
            if [ ! ${CONTAINER} ]; then
                echo "It seems that your pull-request to '${LRB}' has not yet been approved" && exit 1
            elif [ ${CONTAINER} == ${ORIGIN_LRB} ]; then
                TARGET=${TRUNK}
            fi
        fi
    fi
    # the very first time that we call finish-rc-fix.sh
    [ ! ${TARGET} ] && TARGET=${LRB}
}

TRUNK=master

fetch_all

RC_FIX=$(git refname)

[[ ${RC_FIX} != *@* ]] && echo "The current branch doesn't seem to be a rc-fix branch" && exit 1

check_upstream ${RC_FIX}

#RCT_PREFIX=rc
#
#LRT=$(git lasttag ${RCT_PREFIX})
LRB=$(get_last_rc_branch)
set_TARGET ${LRB}

echo "TARGET: ${TARGET}"
echo "LRB: ${LRB}"

merge_to_target() {
    BASE=${1}
    COMPARE=${2}
    NOTES=${3}
    OBJECT=${4}
    git pull-request ${BASE} ${COMPARE}
    overwrite_and_push_notes ${NOTES} ${OBJECT}
}

push_and_merge() {
    git push -f origin ${RC_FIX} & PUSH_PID=$!
    wait ${PUSH_PID} \
        && merge_to_target ${TRUNK} ${RC_FIX} finish \
        || overwrite_and_push_notes err_push ${UPSTREAM_OBJECT}
}

UPSTREAM_OBJECT=$(git rev-parse $(git upstream))
if [ ${TARGET} == ${LRB} ]; then
    # This script branch get executed the first time to merge the fix into the rc-branch
    echo "Trying to create a pull request in '${LRB}'"
    MERGE_BASE=$(git merge-base ${RC_FIX} ${LRB})
    merge_to_target ${LRB} ${RC_FIX} ${MERGE_BASE} ${RC_FIX}
elif [ ${TARGET} == ${TRUNK} ]; then
    # This script branch get executed the second time to merge the fix into TRUNK
    echo "Trying to create a pull request in '${TRUNK}'"
	MERGE_BASE=$(get_notes ${UPSTREAM_OBJECT})
    echo "git rebase --onto $(git upstream ${TRUNK}) ${MERGE_BASE} ${RC_FIX}"
	git rebase --onto $(git upstream ${TRUNK}) ${MERGE_BASE} ${RC_FIX}
	RET=$(echo $?)

    # TODO
    # 1. Stress test a broken rebase!
    # 2. Stress test a broken push?
	if [ ${RET} == "0" ]; then
#        git push -f origin ${RC_FIX} & PUSH_PID=$!
#        wait ${PUSH_PID} \
#            && merge_to_target ${TRUNK} ${RC_FIX} finish \
#            || overwrite_and_push_notes err_push ${UPSTREAM_OBJECT}
        push_and_merge
	else
    	overwrite_and_push_notes err_rebase ${UPSTREAM_OBJECT}
    	echo
		echo "After having solved the rebase you MUST pull request ${RC_FIX} on master"
        echo
	fi
elif [[ ${TARGET} == *err_* ]]; then
#    git push -f origin ${RC_FIX} & PUSH_PID=$!
#    wait ${PUSH_PID} \
#        && merge_to_target ${TRUNK} ${RC_FIX} finish \
#        || overwrite_and_push_notes err_push ${UPSTREAM_OBJECT}
    push_and_merge
elif [ ${TARGET} == finish ]; then
    #TODO we could provide some information about the PR status...
    echo "Everything done"
fi
