#!/bin/bash

[ "$#" -ne 3 ] && {
  echo "$0 [DATABASE] [DATABASEHOST] [PORT]"
  exit 1
}

DATABASE=$1
DATABASEHOST=$2
PORT=$3

psql="psql -h $DATABASEHOST -U postgres -d $DATABASE"
psqlAdd="$psql -c 'insert into testtable values(1);'"
psqlRemove="$psql -c 'delete from testtable where id = 1;'"
psqlCount="$psql -q -c 'select count(*) from testtable;'"

# create db schema
$psql -c 'create table if not exists testtable(id serial primary key);' || exit 1

while true; do
  cnt=$(eval $psqlCount |head -3 |tail -n 1 |tr -d '[:space:]')
  req=$(echo -e "HTTP/1.1 200 OK\n\n$cnt" | nc -c -l -p $PORT 0.0.0.0)
  if [[ $req =~ '/add' ]]; then
    eval $psqlAdd
  fi
  if [[ $req =~ '/remove' ]]; then
    eval $psqlRemove
  fi
done
