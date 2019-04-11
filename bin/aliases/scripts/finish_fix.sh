. $PWD/trunk-flow/aliases/scripts/utils.sh

#FIX_TYPES: hc-fix, hc-inhibit, rc-fix, rc-inhibit
FIX_TYPE=$1

set_TARGET() {
    echo "set_TARGET::"
    FIX=$(git refname)
    FIX_ORIGIN=$(get_remote ${FIX})
    FIRST_TARGET=${1}
    SECOND_TARGET=${2}
    [ ${FIRST_TARGET} ] && FIRST_TARGET_ORIGIN=$(get_remote ${FIRST_TARGET})
    [ ${SECOND_TARGET} ] && SECOND_TARGET_ORIGIN=$(get_remote ${SECOND_TARGET})
    if [ "$(git rev-parse HEAD)" == "$(git rev-parse ${FIRST_TARGET_ORIGIN})" ]; then
        echo "error: The current branch '$(git refname)' doesn't have commits yet" && exit 1
    else
        UPSTREAM_NOTES=$(get_notes ${FIX_ORIGIN})
		echo "UPSTREAM_NOTES: $UPSTREAM_NOTES"
        if [ ${UPSTREAM_NOTES} ]; then
            [ ${UPSTREAM_NOTES} ] && [[ ${UPSTREAM_NOTES} == finish ]] && TARGET=finish
            [ ${UPSTREAM_NOTES} ] && [[ ${UPSTREAM_NOTES} == err_* ]] && TARGET=${UPSTREAM_NOTES}

            if [ ! ${TARGET} ]; then
                if [ ! "$(contained_into ${FIRST_TARGET_ORIGIN} ${FIX_ORIGIN})" ] && [ ! "$(contained_into ${SECOND_TARGET_ORIGIN} ${FIX_ORIGIN})" ]; then
                    if [ "$(contained_into ${SECOND_TARGET_ORIGIN} ${UPSTREAM_NOTES})" ]; then
                        if [ "$(contained_into ${FIRST_TARGET_ORIGIN} ${UPSTREAM_NOTES})" ]; then
                            echo "It seems that your pull-request to '${FIRST_TARGET}' has not yet been merged" && exit 1
                        else
                            echo "It seems that your pull-request to '${SECOND_TARGET}' has not yet been merged" && exit 1
                        fi
                    elif [ "$(contained_into ${FIRST_TARGET_ORIGIN} ${UPSTREAM_NOTES})" ]; then
                        echo "It seems that your pull-request to '${FIRST_TARGET}' has not yet been merged" && exit 1
                    fi
                elif [ "$(contained_into ${FIRST_TARGET_ORIGIN} ${FIX_ORIGIN})" ] && [ ! "$(contained_into ${SECOND_TARGET_ORIGIN} ${FIX_ORIGIN})" ]; then
                    echo "Falling back to SECOND_TARGET=${SECOND_TARGET}"
                    TARGET=${SECOND_TARGET}
                elif [ "$(contained_into ${SECOND_TARGET_ORIGIN} ${FIX_ORIGIN})" ]; then
                    echo "Falling back to ${TRUNK}"
                    TARGET=${TRUNK}
                fi
            fi
        else
            TARGET=${FIRST_TARGET}
        fi
    fi
    echo "::set_TARGET"
}

TRUNK=master

fetch_all

FIX=$(git refname)

case "${FIX_TYPE}" in
    hc-fix) [[ ${FIX} != hotfix* ]] && echo "The current branch doesn't seem to be an 'hotfix' branch" && exit 1;;
    hc-inhibit) [[ ${FIX} != *#* ]] && echo "The current branch doesn't seem to be a 'hc-inhibit' branch" && exit 1;;
    rc-fix) [[ ${FIX} != *@* ]] && echo "The current branch doesn't seem to be a 'rc-fix' branch" && exit 1;;
    rc-inhibit) [[ ${FIX} != *#* ]] && echo "The current branch doesn't seem to be a 'rc-inhibit' branch" && exit 1;;
esac

case "${FIX_TYPE}" in
    hc-fix|hc-inhibit)
        LHB=$(get_last_hc_branch prod)

        if [ "${FIX_TYPE}" == "hc-fix" ]; then
            LRB=$(get_last_rc_branch prod)
            # If there is a rc-branch ongoing LRB should be not empty
            # otherwise TRUNK will take its place
            set_TARGET ${LHB} ${LRB} ${TRUNK}
            # We need to check the upstream only the first time
            # TODO check better if this is correct. If happens a conflict resolution in the second run?
            [ "${TARGET}" == "${LHB}" ] && check_upstream ${FIX}
        elif [ "${FIX_TYPE}" == "hc-inhibit" ]; then
        	[ ! ${LHB} ] && echo "Cannot finish '${FIX}' since there is no hc-branch ongoing!!!" && exit 1
            check_upstream ${FIX}
            set_TARGET ${LHB} finish
        fi ;;
    rc-fix|rc-inhibit)
        LRB=$(get_last_rc_branch prod)

        if [ "${FIX_TYPE}" == "rc-fix" ]; then
            set_TARGET ${LRB} ${TRUNK}
            # We need to check the upstream only the first time
            # TODO check better if this is correct. If happens a conflict resolution in the second run?
            [ "${TARGET}" == "${LRB}" ] && check_upstream ${FIX}
        elif [ "${FIX_TYPE}" == "rc-inhibit" ]; then
        	[ ! ${LRB} ] && echo "Cannot finish '${FIX}' since there is no rc-branch ongoing!!!" && exit 1
            check_upstream ${FIX}
            set_TARGET ${LRB} finish
        fi ;;
    *) echo "This type of fix '${FIX_TYPE}' is not supported!" && exit 1
esac

merge_to_target() {
    BASE=${1}
    COMPARE=${2}
    NOTES=${3}
    OBJECT=${4}
#    echo "merge_to_target::"
#    echo "BASE ${BASE}"
#    echo "COMPARE ${COMPARE}"
#    echo "NOTES ${NOTES}"
#    echo "OBJECT ${OBJECT}"
    echo "git pull-request ${BASE} ${COMPARE}"
#    exit
    git pull-request ${BASE} ${COMPARE} & PR_PID=$!
    wait ${PR_PID} \
        && overwrite_and_push_notes ${NOTES} ${OBJECT} \
        || exit 1
#    echo "::merge_to_target"
}

handle_broken_push(){
	echo "::handle_broken_push"
    TARGET=$1
    FIX=$2
	NOTES=$3
	UPSTREAM_OBJECT=$4
	echo "git push -f origin ${FIX} --no-verify"
	git push -f origin ${FIX} --no-verify && \
    echo "overwrite_and_push_notes \"err_push,${TARGET},${NOTES}\" ${UPSTREAM_OBJECT}" && \
	overwrite_and_push_notes "err_push,${TARGET},${NOTES}" ${UPSTREAM_OBJECT}
}

handle_broken_rebase(){
	echo "::handle_broken_rebase"
    ONTO=$1
    NOTES=$2
    UPSTREAM_OBJECT=$3
    echo "overwrite_and_push_notes \"err_rebase,${ONTO},${NOTES}\" ${UPSTREAM_OBJECT}"
    overwrite_and_push_notes "err_rebase,${ONTO},${NOTES}" ${UPSTREAM_OBJECT}
}

push_and_merge() {
    TARGET=$1
    FIX=$2
    NOTES=$3
    UPSTREAM_OBJECT=$4

    echo "git push -f origin ${FIX}"
    git push -f origin ${FIX} & PUSH_PID=$!
    # TODO Stress test a broken push!
    # A push can return non zero status because of hooks. Is this scenery handled correctly?
    wait ${PUSH_PID} \
        && merge_to_target ${TARGET} ${FIX} ${NOTES} ${UPSTREAM_OBJECT} \
        || handle_broken_push ${TARGET} ${FIX} ${NOTES} ${UPSTREAM_OBJECT}
}

rebase_onto() {
    ONTO=$1
    MERGE_BASE=$2
    FIX=$3
    UPSTREAM_OBJECT=$4
    NOTES=$5

    echo "git rebase --onto $(get_remote ${ONTO}) ${MERGE_BASE} ${FIX}"
	git rebase --onto $(get_remote ${ONTO}) ${MERGE_BASE} ${FIX}
	RET=$(echo $?)

	if [ ${RET} == "0" ]; then
        [ ! ${NOTES} ] && NOTES=$(git merge-base ${FIX} $(get_remote ${ONTO}))
        FUTURE_UPSTREAM_OBJECT=$(git rev-parse HEAD)
        push_and_merge ${ONTO} ${FIX} ${NOTES} ${FUTURE_UPSTREAM_OBJECT}
	else
        # TODO Stress test a broken rebase!
	    # A rebase can have conflicts that will cause the git rebase command
	    # above to return non zero. Is this scenery handled correctly?
        handle_broken_rebase ${ONTO} ${NOTES} ${UPSTREAM_OBJECT}
	fi
}

get_merge_base_from_notes() {
    UPSTREAM_OBJECT=$1
	MERGE_BASE=$(get_notes ${UPSTREAM_OBJECT})
    echo ${MERGE_BASE}
}

get_merge_base() {
    FIX=$1
	LHB=$2
    MERGE_BASE=$(git merge-base ${FIX} $(git rev-parse $(get_remote ${LHB})))
    echo ${MERGE_BASE}
}

get_notes_from_err() {
    ERROR=$1
    NOTES=$(cut -d ',' -f3 <<< "${ERROR}")
    echo ${NOTES}
}

get_onto_from_err() {
    ERROR=$1
    ONTO=$(cut -d ',' -f2 <<< "${ERROR}")
    echo ${ONTO}
}

get_target_from_err() {
    ERROR=$1
    TARGET=$(cut -d ',' -f2 <<< "${ERROR}")
    echo ${TARGET}
}

echo "CURRENT_TARGET: ${TARGET}"
#exit
UPSTREAM_OBJECT=$(git rev-parse $(get_remote ${FIX}))
if [ ${LHB} ] && [ ${TARGET} == ${LHB} ]; then
    echo "Trying to create a pull request in '${LHB}'"
    if [ "${FIX_TYPE}" == "hc-inhibit" ]; then
         # Merge ONLY in the current hc-branch!
         merge_to_target ${LHB} ${FIX} finish ${UPSTREAM_OBJECT}
    elif [ "${FIX_TYPE}" == "hc-fix" ]; then
        NEXT_MERGE_BASE=$(get_merge_base ${FIX} ${LHB})
        merge_to_target ${LHB} ${FIX} ${NEXT_MERGE_BASE} ${UPSTREAM_OBJECT}
    fi
elif [ ${LRB} ] && [ ${TARGET} == ${LRB} ]; then
    echo "Trying to create a pull request in '${LRB}'"
    if [ "${FIX_TYPE}" == "rc-inhibit" ]; then
         # Merge ONLY in the current rc-branch!
         merge_to_target ${LRB} ${FIX} finish ${UPSTREAM_OBJECT}
    elif [ "${FIX_TYPE}" == "rc-fix" ]; then
        NEXT_MERGE_BASE=$(get_merge_base ${FIX} ${LRB})
        merge_to_target ${LRB} ${FIX} ${NEXT_MERGE_BASE} ${FIX}
    elif [ "${FIX_TYPE}" == "hc-fix" ]; then
        PREV_MERGE_BASE=$(get_merge_base_from_notes ${UPSTREAM_OBJECT})
        rebase_onto ${LRB} ${PREV_MERGE_BASE} ${FIX} ${UPSTREAM_OBJECT}
    fi
elif [ ${TARGET} == ${TRUNK} ]; then
    echo "Trying to create a pull request in '${TRUNK}'"
    PREV_MERGE_BASE=$(get_merge_base_from_notes ${UPSTREAM_OBJECT})
    rebase_onto ${TRUNK} ${PREV_MERGE_BASE} ${FIX} ${UPSTREAM_OBJECT} finish
elif [[ ${TARGET} == err_* ]]; then
    # TODO test this (related to failing rebase and failing push)!!!
    echo "An error occurred: ${TARGET}"
    FUTURE_UPSTREAM_OBJECT=$(git rev-parse HEAD)
    case "${TARGET}" in
        err_rebase*)
                echo "err_rebase*"
                ONTO=$(get_onto_from_err ${TARGET})
                echo "ONTO: $ONTO"
                NOTES=$(get_notes_from_err ${TARGET})
				echo "NOTES: $NOTES"
                [ ! ${NOTES} ] && NOTES=$(git merge-base ${FIX} $(get_remote ${ONTO}))
				echo "NOTES: $NOTES"
                push_and_merge ${ONTO} ${FIX} ${NOTES} ${FUTURE_UPSTREAM_OBJECT} ;;
        err_push*)
                echo "err_push*"
                FUTURE_NOTES=$(get_notes_from_err ${TARGET})
                FUTURE_TARGET=$(get_target_from_err ${TARGET})
				echo "FUTURE_TARGET: ${FUTURE_TARGET}"
				echo "FUTURE_NOTES: ${FUTURE_NOTES}"
                echo "FUTURE_UPSTREAM_OBJECT: ${FUTURE_UPSTREAM_OBJECT}"
                echo "push_and_merge ${FUTURE_TARGET} ${FIX} ${FUTURE_NOTES} ${FUTURE_UPSTREAM_OBJECT}"
                push_and_merge ${FUTURE_TARGET} ${FIX} ${FUTURE_NOTES} ${FUTURE_UPSTREAM_OBJECT} ;;
    esac
elif [ ${TARGET} == finish ]; then
    case "${FIX_TYPE}" in
        hc-fix|rc-fix) TARGET=${TRUNK} ;;
        rc-inhibit) TARGET=${LRB} ;;
        hc-inhibit) TARGET=${LHB} ;;
    esac
    handle_finish ${TARGET} ${FIX}
fi
