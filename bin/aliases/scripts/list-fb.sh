case "${1}" in
    create) CREATE=true;;
    script) SCRIPT=true;;
    *) HUMAN=true;;
esac

RCT_PREFIX=rc
if [ ${CREATE} ]; then
    # This script branch will be called always from create-rc.sh script so is not necessary to fetch.
    PRT_PREFIX=prod
    TRUNK=master

    LRT=$(git lasttag ${RCT_PREFIX})

    FEATURES=$2
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
else
    # We need to retrieve already created FEATURES list
    FEATURES=$(git notes show $(git lasttag ${RCT_PREFIX}))
    if [ ${SCRIPT} ]; then
        echo "${FEATURES}"
    elif [ ${HUMAN} ]; then
        IFS=','
        for FB in ${FEATURES}
        do
            echo "${FB}"
        done
    fi
fi


