#!/bin/bash
base=$(cd $(dirname $0)/..;pwd)

DAMENG_IMAGE_DIR=${DAMENG_IMAGE_DIR:-/tmp/files}
DAMENG_IMAGE=${DAMENG_IMAGE:-dm8_20230104_x86_rh6_64.iso}
DAMENG_VERSION=${DAMENG_VERSION:-$(echo $DAMENG_IMAGE|sed 's/\..*//')}
DAMENG_ARCH=${DAMENG_ARCH:-x86_64-linux}
DAMENG_NAME=${DAMENG_NAME:-$(echo ${DAMENG_VERSION}|sed 's/x86.*//'|sed 's/\_/\-/g')${DAMENG_ARCH}}
DAMENG_PACKGE=${DAMENG_NAME}.tar.gz
DAMENG_BASE=${DAMENG_BASE:-Dameng}
BUILD_TEMP=${BUILD_TEMP:-/tmp/build/$DAMENG_NAME/temp}
BUILD_INST=${BUILD_INST:-/opt/$DAMENG_BASE}
BUILD_DIST=${BUILD_DIST:-/dist}
P7ZIP_EXEC=${P7ZIP_EXEC:-7za}

[ -z "$DAMENG_VERSION" ] && exit 1

function help {
echo "HELP"
}

function arch {
cd "$BUILD_INST"

[ -d "$BUILD_INST/${DAMENG_VERSION}" ] && \
mv "${DAMENG_VERSION}" "${DAMENG_NAME}"

[ ! -d "${DAMENG_NAME}" ] && return 2

retval=0
tar czf "$BUILD_DIST"/${DAMENG_PACKGE} "${DAMENG_NAME}"
retval=$?

return $retval
}

function make {
rm -rf   "$BUILD_TEMP"
mkdir -p "$BUILD_TEMP"
cd       "$BUILD_TEMP"
$P7ZIP_EXEC x "$DAMENG_IMAGE_DIR/$DAMENG_IMAGE"
rm -f    DMInstall
mkdir -p DMInstall
cd       DMInstall
tar xf   "$BUILD_TEMP"/Install.tar
rm -rf   "$BUILD_INST"
mkdir -p "$BUILD_INST"
cd       "$BUILD_INST"

DM_HOME="$BUILD_INST/$DAMENG_VERSION"
mkdir -p "$DM_HOME"

[ -x "$BUILD_TEMP/DMInstall/source/jdk/bin/java" ] && \
JAVA_HOME=$BUILD_TEMP/DMInstall/source/jdk

export DM_INSTALL_TMPDIR=$BUILD_TEMP
export DM_JAVA_HOME=$JAVA_HOME

$BUILD_TEMP/DMInstall/source/script/ckdmstat.sh >/dev/null
CKDMSTAT=$?
echo CKDMSTAT=$CKDMSTAT

if [ $CKDMSTAT -eq 8 ]; then
cat <<EOF  | tee $BUILD_TEMP/Install.txt
y
EOF
else
echo -n "" | tee $BUILD_TEMP/Install.txt
fi

cat <<EOF  | tee -a $BUILD_TEMP/Install.txt
n
n
1
$DM_HOME
y
y
EOF

retval=0
cat $BUILD_TEMP/Install.txt | \
$BUILD_TEMP/DMInstall/install/install.sh
retval=$?

return $retval
}

function main {
action=$1
[ -z "$action" ] && action=help
shift
"$action" "$@"
}

main "$@"
