git fetch -tp
git fetch origin refs/notes/commits:refs/notes/commits

RCT_PREFIX=rc
RCB_PREFIX="${RCT_PREFIX}-branch"

create_rc_branch_name() {
    RCT=$1
    VER=${RCT:$((${#RCT_PREFIX}+1))}
    echo "${RCB_PREFIX}-${VER}"
}

LRT=$(git lasttag ${RCT_PREFIX})
LRB=$(create_rc_branch_name ${LRT})

[[ $(git refname) == ${LRB} ]] && echo "You are trying to remove this branch, leave it to proceed" && exit 1

if [[ $(git cherry $(git lasttag prod) ${LRB}) ]]; then
    # We should have active the protection rule on: rc-branch-v*
    # so we need first to disable it before aborting a rc-branch
    # We try first to delete the remote branch and catch the rejection (protected branch hook declined)
    # to not dirty local
    git branch --unset-upstream ${LRB}
    git push origin --delete --no-verify ${LRB}
    RET=$(echo $?)
	if [ ${RET} == "0" ]; then
	    # The protection rule was disabled so we can remove branch and tag
	    # both locally and remotely
        git branch -D ${LRB}
        git notes remove ${LRT}
        git tag -d ${LRT}
        git push --delete origin ${LRT} --no-verify
        git push origin refs/notes/commits --no-verify
        echo
        echo "Please remember to re-enable the protection rule ASAP\n"
    else
        # Since we haven't deleted the remote we need to re-set the previously unset upstream
        git branch --set-upstream-to="origin/${LRB}" ${LRB} &>/dev/null
        echo "To abort an ongoing rc-branch you must TEMPORARILY disable the protection rule set on: rc-branch-v*"
	fi

else
    echo "There is no rc-branch ongoing"
fi
