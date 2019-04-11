. $PWD/trunk-flow/aliases/scripts/utils.sh
fetch_all
HC_BRANCH=$(get_last_hc_branch prod)
if [ ${HC_BRANCH} ]; then
    echo "${HC_BRANCH}"
else
    echo "There is not an ongoing hc-branch"
fi
