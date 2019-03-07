RCT=$1
# If provided, this version will be used. In this case you could provide also only the RCT prefix without the
# -v* part
RCT_VERSION=$2

[ ! ${RCT} ] && echo "You must provide the rc tag from which create the rc-branch"

RCT_PREFIX=$(cut -d '-' -f1 <<< "${RCT}")
[ ! ${RCT_VERSION} ] && RCT_VERSION=$(cut -d '-' -f2 <<< "${RCT}")
RCB_PREFIX="${RCT_PREFIX}-branch"

echo "${RCB_PREFIX}-${RCT_VERSION}"
