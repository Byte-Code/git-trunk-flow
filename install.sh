VERSION=v0.17.0
CUR_VERSION=$(git trunk 2>/dev/null)
DEST=trunk-flow

upgrade() {
    DEST=$1
    ARCHIVE_BIN_PATH="git-trunk-flow-$(echo ${VERSION} | sed 's/^v//g')/bin/"
    curl https://codeload.github.com/Byte-Code/git-trunk-flow/tar.gz/${VERSION} | tar -xvf - -C ./${DEST} --strip-components=2 ${ARCHIVE_BIN_PATH}
}

install() {
    DEST=$1
    mkdir ${DEST}
    upgrade ${DEST}
    INCLUDE=$(cat << EOF
[include]
    path = "../${DEST}/root"
EOF)

    echo "${INCLUDE}" >> .git/config
    echo "${DEST}/" >> .git/info/exclude
}

if [ ! ${CUR_VERSION} ] || [ ${CUR_VERSION} != ${VERSION} ]; then
    if [ ! ${CUR_VERSION} ]; then
        echo "git-trunk-flow: installing ${VERSION}"
        install ${DEST}
    else
        echo "git-trunk-flow: upgrading from ${CUR_VERSION} to ${VERSION}"
        upgrade ${DEST}
    fi
else
    echo "git-trunk-flow: Already up to date."
fi
