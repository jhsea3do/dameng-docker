#!/bin/bash
DM_HOME=${DM_HOME:-$HOME/opt/dmdbms/dmv8}
DM_DATA=${DM_DATA:-$HOME/opt/dmdbms/data}
DM_LOGS=${DM_LOGS:-$HOME/opt/dmdbms/logs}
DM_NAME=${DM_NAME:-DEMO}
DM_PORT=${DM_PORT:-5236}
DM_PAWD=${DM_PAWD:-DAMENG123456}
DM_VERSION=${DM_VERSION:-dm8_20230104_x86_rh6_64}
PATH=$DM_HOME/bin:$DM_HOME/tool:$PATH
LD_LIBRARY_PATH=$DM_HOME/bin:$DM_HOME/bin2:$DM_HOME/tool:$LD_LIBRARY_PATH
# https://blog.csdn.net/Mervin_Fmy/article/details/114012705
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH

if [ "$1" = "run" ]; then
$DM_HOME/bin/dmserver $DM_DATA/$DM_NAME/dm.ini
elif [ "$1" = "init" ]; then
# https://eco.dameng.com/document/dm/zh-cn/pm/dminit-parameters.html
DB_NAME=${DM_NAME}
SYSDBA_PWD=${SYSDBA_PWD:-$DM_PAWD}
SYSAUDITOR_PWD=${SYSAUDITOR_PWD:-$DM_PAWD}
CASE_SENSITIVE=${CASE_SENSITIVE:-"Y"}
PORT_NUM=${DM_PORT}
UNICODE_FLAG=${UNICODE_FLAG:-1}
if [[ "$2" = "--force" || "$2" == "-f" ]]; then
$SHELL $0 purge "$2"
fi
if [ -f "$DM_DATA/$DB_NAME/dm.ini" ]; then
ls -la "$DM_DATA/$DB_NAME/dm.ini"
echo "! add force option or skip init ..." && exit 0
fi
echo "! init..." && \
mkdir -p $DM_DATA && \
mkdir -p $DM_LOGS && \
$DM_HOME/bin/dminit \
"DB_NAME=$DB_NAME" \
"PATH=$DM_DATA" \
"SYSDBA_PWD=$SYSDBA_PWD" \
"SYSAUDITOR_PWD=$SYSAUDITOR_PWD" \
"CASE_SENSITIVE=$CASE_SENSITIVE" \
"PORT_NUM=$PORT_NUM" \
"UNICODE_FLAG=$UNICODE_FLAG"
elif [ "$1" = "start" ]; then
DB_NAME=$DM_NAME
DM_PID=$($SHELL $0 pid)
if [ -z "$DM_PID" ]; then
if [ ! -f "$DM_DATA/$DB_NAME/dm.ini" ]; then
retval=0
$SHELL $0 init
retval=$?
[ "$retval" -ne 0 ] && \
exit $retval
fi
echo "! starting..." && \
$SHELL $0 run 2>&1 | tee -a $DM_LOGS/dmctl.sh.log
else
echo "! already started." && exit 0
fi
elif [ "$1" = "status" ]; then
ps -ef|grep dmserver|grep $DM_NAME|grep dm.ini
elif [ "$1" = "pid" ]; then
$SHELL $0 status|awk '{print $2}'
elif [ "$1" = "disql" ]; then
shift
$DM_HOME/bin/disql "$@"
elif [ "$1" = "dbinit" ]; then
shift
db_addr=localhost
db_port=$DM_PORT
sa_user=SYSDBA
sa_pass=$DM_PAWD
db_user=$1
db_pass=$2
db_name=$3
[ -z "$db_user" ] && \
echo "! db_user can not be empty" && exit 1
[ -z "$db_pass" ] && \
echo "! db_pass can not be empty" && exit 1
[ -z "$db_name" ] && \
echo "! db_name can not be empty" && exit 1
sql_conn="$sa_user/$sa_pass@$db_addr:$db_port"
cat <<EOF | $SHELL $0 disql -L "$sql_conn" >/dev/null 2>&1
SELECT * FROM V\$PARAMETER WHERE NAME='PWD_POLICY';
ALTER SYSTEM SET 'PWD_POLICY'=0 BOTH;
CREATE USER $db_user IDENTIFIED BY $db_pass DISKSPACE UNLIMITED;
ALTER USER $db_user IDENTIFIED BY $db_pass;
GRANT RESOURCE TO $db_user;
EOF
else
if [ -z "$1" ]; then
$SHELL $0 start
exit 0
fi
shift
"$@"
fi

