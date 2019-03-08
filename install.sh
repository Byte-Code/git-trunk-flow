VERSION=v0.1.0
CUR_VERSION=$(git trunk 2>/dev/null)
DEST=trunk-flow

upgrade() {
    DEST=$1
    svn export --force https://github.com/Byte-Code/git-trunk-flow/tags/${VERSION}/bin ${DEST} --non-interactive --trust-server-cert
}

install() {
    DEST=$1
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
