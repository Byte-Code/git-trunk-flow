. $PWD/trunk-flow/aliases/scripts/utils.sh

git fetch -tp

RELEASE_BRANCH=${1}

if [ ! "${RELEASE_BRANCH}" ]; then
    echo "You must specify a remote branch where to release the current HEAD!" && exit 1
fi

echo "Are you sure to push the current HEAD to '${RELEASE_BRANCH}'?"
read -p "y|n) " DO_RELEASE
case "${DO_RELEASE}" in
    [yY][eE][sS]|[yY])
        echo "git push -f origin HEAD:${RELEASE_BRANCH} --no-verify"
        git push -f origin HEAD:${RELEASE_BRANCH} --no-verify
        ;;
    *) echo "aborting!" ;;
esac
