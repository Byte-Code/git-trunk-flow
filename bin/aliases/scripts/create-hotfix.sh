. $PWD/trunk-flow/aliases/scripts/utils.sh

git fetch -tp

PRT_PREFIX=prod
LHB=$(get_last_hc_branch ${PRT_PREFIX} --force)

usage() {
    echo "error: git create-hotfix <TP_ID|desc>"
}

HF_NAME=$1

[ ! ${HF_NAME} ] && usage && exit 1

LPT=$(git lasttag ${PRT_PREFIX})

create_hotfix_branch() {
    HF_NAME=$1
    [[ ${HF_NAME} != hotfix/* ]] && HF_NAME="hotfix/${HF_NAME}"
    START_POINT=$2
    git checkout --no-track -b "${HF_NAME}" ${START_POINT}
}

REMOTE_LHB=$(get_remote ${LHB})

if [ ! ${REMOTE_LHB} ]; then
    git branch ${LHB} ${LPT}
    git push --no-verify --set-upstream origin ${LHB}
    create_hotfix_branch ${HF_NAME} ${LHB}
else
    create_hotfix_branch ${HF_NAME} ${REMOTE_LHB}
fi
