#!/bin/sh
base=$(cd $(dirname $0)/..; pwd)
APP_IMAGE=dameng:dm8-20230104-x86_64-linux
APP_PORT=5236
APP_NAME=dameng

DB_USER=orchestrator
DB_PASS=passw0rd
DB_NAME=orchestrator
DB_ADDR=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-$APP_PORT}

TEST_NAME=test1

docker rm -f $APP_NAME

mkdir -p  $base/temp/$TEST_NAME

docker run -v "$base/temp:/tmp/temp" -u root \
  --rm --name ${APP_NAME}_temp --entrypoint "" -it "$APP_IMAGE" \
  bash -c "mkdir -p /tmp/temp/$TEST_NAME/data; chown -R 5236:5236 /tmp/temp/$TEST_NAME/data"

ls -la $base/temp/$TEST_NAME

docker run --name $APP_NAME -d -p "$DB_PORT:$APP_PORT" \
  -v "$base/temp/$TEST_NAME/data:/opt/Dameng/data" \
  "$APP_IMAGE" >/dev/null 2>&1 &
sleep 30

docker logs    $APP_NAME

docker exec -i $APP_NAME bash -c "/docker-entrypoint.sh dbinit $DB_USER $DB_PASS $DB_NAME"

cat <<EOF | docker exec -i $APP_NAME bash -c "/docker-entrypoint.sh disql -L $DB_USER/$DB_PASS@$DB_ADDR:$DB_PORT"
create table t1 (id number(5) primary key, name varchar2(10));
select table_name from user_tables;
desc t1;
EOF

docker rm -f   $APP_NAME

find $base/temp

docker run --name $APP_NAME -d -p "$DB_PORT:$APP_PORT" \
  -v "$base/temp/$TEST_NAME/data:/opt/Dameng/data" \
  "$APP_IMAGE" >/dev/null 2>&1 &
sleep 30

cat <<EOF | docker exec -i $APP_NAME bash -c "/docker-entrypoint.sh disql -L $DB_USER/$DB_PASS@$DB_ADDR:$DB_PORT"
select table_name from user_tables;
desc t1;
drop table t1;
select table_name from user_tables;
EOF

docker rm -f   $APP_NAME

docker run -v "$base/temp:/tmp/temp" -u root \
  --rm --name ${APP_NAME}_temp --entrypoint "" -it "$APP_IMAGE" \
  bash -c "rm -rf /tmp/temp/$TEST_NAME"
