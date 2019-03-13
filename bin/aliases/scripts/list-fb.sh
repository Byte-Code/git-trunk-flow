. $PWD/trunk-flow/aliases/scripts/utils.sh

fetch_all

case "${1}" in
    create) CREATE=true;;
    script) SCRIPT=true;;
    preview) PREVIEW=true;;
    *) HUMAN=true;;
esac

RCT_PREFIX=rc
PRT_PREFIX=prod
TRUNK=master

create() {
    FEATURES=$1
    LRT=$(git lasttag ${RCT_PREFIX})
    # Retrieve messages of new testable fb
    # Filtering out hotfixes (grep -v 'hotfix') and rc fixes (grep -v '@')
    MESSAGES=$(git log ${LRT}..$(git upstream ${TRUNK}) --first-parent --oneline --pretty=format:'%s' | grep -v 'hotfix' | grep -v '@')

    # Getting information from pull-request merge messages
    IFS=$'\n'
    for MESSAGE in ${MESSAGES}
    do
        # e.g. MESSAGE: Merge pull request #N from Byte-Code/<fb/><TP|desc>
        FB=$(echo ${MESSAGE} | awk -F 'from' '{print $2}')
        FB=$(cut -d '/' -f2 -f3 <<< "${FB}")

        if [ "${FEATURES}" ]; then
            # avoid duplicates
            [[ ${FEATURES} != *"${FB}"* ]] && FEATURES="${FEATURES},${FB}"
        else
            FEATURES="${FB}"
        fi
    done
    echo "${FEATURES}"
}

output_human() {
    FEATURES=$1
    IFS=','
    for FB in ${FEATURES}
    do
        echo "${FB}"
    done
}

if [ ${CREATE} ]; then
    # When called by create-rc.sh script the second argument may contains a list
    # on inhibited features that actually haven't been tested
    create "${2}"
elif [ ${PREVIEW} ]; then
    FEATURE_INHIBIT=$(get_features_inhibit $(git list-fb script))
    output_human $(create ${FEATURE_INHIBIT})
else
    # We retrieve the already created FEATURES list
    FEATURES=$(get_notes $(git lasttag ${RCT_PREFIX}))
    if [ ${SCRIPT} ]; then
        echo "${FEATURES}"
    elif [ ${HUMAN} ]; then
        output_human ${FEATURES}
    fi
fi


