. $PWD/trunk-flow/aliases/scripts/utils.sh
fetch_all
RC_BRANCH=$(get_last_rc_branch prod)
if [ ${RC_BRANCH} ]; then
    echo "${RC_BRANCH}"
else
    echo "There is not an ongoing rc-branch"
fi
