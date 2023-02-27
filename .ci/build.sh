#!/bin/bash
base=$(cd $(dirname $0)/..; pwd)

DAMENG_IMAGE=dm8_20230104_x86_rh6_64.iso
DAMENG_NAME=dm8-20230104-x86_64-linux
DAMENG_IMAGE_LINK=https://cclna.oss-cn-zhangjiakou.aliyuncs.com/depends/dameng/$DAMENG_IMAGE

function dl {
name=$1
shift
file=$1
shift
link="$@"
rtn=0
mkdir -p "$temp"
rtn=$?
[ $rtn -ne 0 ] && \
return $rtn
if [ -f "$temp/$file" ]; then
echo "! skip $name"
else
echo "! load $name - $link"
curl -o "$temp/$file" "$link"
rtn=$?
fi
return $rtn
}

temp=$base/files

function build {
docker build -t dameng:$DAMENG_NAME -f .ci/Dockerfile .
}

function main {
dl "dameng" "$DAMENG_IMAGE" "$DAMENG_IMAGE_LINK"
build
}

main "$@"
