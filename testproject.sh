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

tmplog=$(mktemp)
# listen and serve
ncat -l $PORT -o $tmplog -k -c 'echo -e "HTTP/1.1 200 OK\n\n$('\
'eval $psqlCount |head -3 |tail -n 1 |tr -d \"[:space:]\")"' &

while inotifywait -qq -e close_write $tmplog; do
  req=$(grep GET $tmplog |tail -1)
  remote=$(echo $req |cut -d' ' -f2 |cut -d@ -f2)
  if [[ $req =~ '/add' ]]; then
    if [[ "$remote" == "/add" ]]; then
      eval $psqlAdd
    else
      curl http://$remote/add
    fi
  fi
  if [[ $req =~ '/remove' ]]; then
    if [[ "$remote" == "/remove" ]]; then
      eval $psqlRemove
    else
      curl http://$remote/remove
    fi
  fi
done
