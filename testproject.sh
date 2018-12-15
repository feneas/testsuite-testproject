#!/bin/bash

[ "$#" -ne 3 ] && {
  echo "$0 [DATABASE] [DATABASEHOST] [PORT]"
  exit 1
}

DATABASE=$1
DATABASEHOST=$2
PORT=$3

tmpLog=$(mktemp)
psql="psql -h $DATABASEHOST -U postgres -d $DATABASE"
psqlAdd="$psql -c 'insert into testtable values(1);'"
psqlRemove="$psql -c 'delete from testtable where id = 1;'"
psqlCount="$psql -q -c 'select count(*) from testtable;'"

# create db schema
$psql -c 'create table if not exists testtable(id serial primary key);' || exit 1

# listen and serve
cmd=$psqlCount' |head -3 |tail -1 |tr -d "[:space:]"'
cmd="echo \"HTTP/1.1 200 OK\n\n\"\$($cmd)"
ncat -l $PORT -o $tmpLog -k -c "$cmd" &
ncatPID=$!

function clean_up() {
  kill $ncatPID
  exit
}
# clean up child process first
trap clean_up SIGHUP SIGINT SIGTERM

while inotifywait -qq -e modify $tmpLog; do
  req=$(grep GET $tmpLog |tail -1)
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
