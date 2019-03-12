. $PWD/trunk-flow/aliases/scripts/utils.sh

next_branch() {
    FB=${1}
    SEP=${2}
    LAST_BRANCH=$(git log $(git lasttag ${RCT_PREFIX})..HEAD --first-parent --oneline --pretty=format:'%s' | grep "${SEP}" | grep "${FB}" | head -n 1 | awk -F 'from' '{print $2}')
    NEXT_VER=1
    if [ ${LAST_BRANCH} ]; then
        LAST_VER=$(cut -d "${SEP}" -f2 <<< "${LAST_BRANCH}")
        if [ ${LAST_VER} ]; then
            NEXT_VER=$((${LAST_VER}+1))
        fi
    fi
    echo "${FB}${SEP}${NEXT_VER}"
}

FB=${1}
SEP=@
[ ${2} ] && SEP=${2}

[ ! ${FB} ] && echo "fb branch name is a required param" && exit 1

RCT_PREFIX=rc
PRT_PREFIX=prod

fetch_all

LRB=$(get_last_rc_branch)
LPT=$(git lasttag ${PRT_PREFIX})

if [ ! "$(git cherry ${LPT} $(get_remote ${LRB}))" ]; then
    echo "The last rc-branch is '${LRB}' and seems to point to the same commit"
    echo "of '${LPT}' which is the last prod tag."
    echo "Probably you forgot to create the rc-branch with \"git create-rc\" command"
else
    if [[ ! $(git list-fb script) == *"${FB}"* ]]; then
        echo "warning: ${FB} doesn't seem to have been released in ${LRB}"
    fi

    RC_FIX=$(next_branch ${FB} ${SEP})
    git checkout --no-track -b ${RC_FIX} $(get_remote ${LRB})
fi
