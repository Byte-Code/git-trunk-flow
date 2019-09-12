. $PWD/trunk-flow/aliases/scripts/utils.sh

FIX=$(git refname)

case "${FIX}" in
    hotfix*) CMD="git finish-hotfix" ;;
    *#*) CMD="git finish-rc-inhibit" ;;
    *@*) CMD="git finish-rc-fix" ;;
    *) CMD="git finish-fb" ;;
esac

echo "$CMD"
${CMD}
