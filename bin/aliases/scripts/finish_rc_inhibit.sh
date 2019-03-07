git fetch -tp
git fetch origin refs/notes/commits:refs/notes/commits

RCB=$(git last-rc --no-fetch)
FBI_NAME=$(git refname)

# Check that rc-branch exists locally...
if [ $(git rev-parse --verify --quiet ${RCB}) ]; then
    if [ ! $(git upstream) ]; then
        git push --set-upstream origin ${FBI_NAME}
    else
        git push origin ${FBI_NAME}
    fi
  	RET=$(echo $?)
	if [ ${RET} == "0" ]; then
        git pull-request ${RCB} ${FBI_NAME}
    else
        echo "An error occurred while trying to push ${FBI_NAME} to its remote.\n"
        echo "Please fix what is needed and re-run this command."
    fi

#	FB_NAME="$(cut -d '!' -f1 <<< "${FBI_NAME}")"
#
#	# Check that feature/bugfix-branch exists...
#	if [ $(git rev-parse --verify --quiet $FB_NAME) ]; then
#		git checkout $RCB
#		# TODO PULL_REQUEST
#		git merge --no-ff $FBI_NAME -m "Merge pull request #XX from Byte-Code/$FBI_NAME"
#	fi
else
	echo "The rc-branch \"${RCB}\" doesn't seem to exist locally. Maybe you forgot to checkout its remote?"
fi
