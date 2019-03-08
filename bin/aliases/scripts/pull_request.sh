. $PWD/trunk-flow/aliases/scripts/utils.sh

BASE_BRANCH=$1

[[ ! ${BASE_BRANCH} ]] && echo "To create a pull request, BASE_BRANCH is mandatory" && exit 1

COMPARE_BRANCH=$2

[[ ! ${COMPARE_BRANCH} ]] && COMPARE_BRANCH=$(git refname)

git fetch -tp

# urlencode <string>
urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case ${c} in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}

get_repo_url() {
	echo $(git config --get remote.origin.url)
}

get_repo_user() {
	REPO_URL=$(get_repo_url)
    if [[ ${REPO_URL} == https* ]]; then
        echo $(cut -d '/' -f4 <<< "${REPO_URL}")
    elif [[ ${REPO_URL} == git* ]]; then
        REPO_USER=$(cut -d ':' -f2 <<< "${REPO_URL}")
        echo $(cut -d '/' -f1 <<< "${REPO_USER}")
    fi
}

get_repo_name() {
	REPO_URL=$(get_repo_url)
	if [[ ${REPO_URL} == https* ]]; then
        REPO_NAME=$(cut -d '/' -f5 <<< "${REPO_URL}")
        echo $(cut -d '.' -f1 <<< "${REPO_NAME}")
    elif [[ ${REPO_URL} == git* ]]; then
        REPO_NAME=$(cut -d ':' -f2 <<< "${REPO_URL}")
        REPO_NAME=$(cut -d '/' -f2 <<< "${REPO_NAME}")
        echo $(cut -d '.' -f1 <<< "${REPO_NAME}")
    fi
}

NO_MERGEABLE_MSG=
NO_MERGEABLE_MSG="${NO_MERGEABLE_MSG}Cannot create a pull request for a branch not mergeable with '$(git upstream ${BASE_BRANCH})'.\n\n"
NO_MERGEABLE_MSG="${NO_MERGEABLE_MSG} (use \"git fetch -tp && git rebase $(git upstream ${BASE_BRANCH}))\" to update your local branch)"

IS_MERGEABLE=$(is_mergeable ${BASE_BRANCH} ${COMPARE_BRANCH})
[[ ! ${IS_MERGEABLE} ]] && echo "${NO_MERGEABLE_MSG}" && exit 1

NO_UPSTREAM_MSG=
NO_UPSTREAM_MSG="${NO_UPSTREAM_MSG}Cannot create a pull request for a branch with no upstream.\n"
NO_UPSTREAM_MSG="${NO_UPSTREAM_MSG}To push the current branch and set the remote as upstream\n\n"
NO_UPSTREAM_MSG="${NO_UPSTREAM_MSG} (use \"git push --set-upstream origin ${COMPARE_BRANCH})"

COMPARE_BRANCH_UPSTREAM=$(git upstream ${COMPARE_BRANCH})
[[ ! ${COMPARE_BRANCH_UPSTREAM} ]] && echo "${NO_UPSTREAM_MSG}" && exit 1

GITHUB_USER=$(get_repo_user)
GITHUB_REPO=$(get_repo_name)

[[ ! ${GITHUB_REPO} || ! ${GITHUB_USER} ]] && echo "Cannot create a pull request without reponame or username" && exit 1
COMPARE_BRANCH=$(urlencode ${COMPARE_BRANCH})
PULL_REQUEST_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}/compare/${BASE_BRANCH}...${COMPARE_BRANCH}?expand=1"
echo "A tab, with the PR in the github compare view, should have be opened in your favourite browser.\n"
echo "For completeness sake, here's the url: ${PULL_REQUEST_URL}"
open ${PULL_REQUEST_URL}





