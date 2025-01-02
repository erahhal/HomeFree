#!/usr/bin/env bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cd "${SCRIPTPATH}/api"
deno task dev &
pids[1]=$!
cd "${SCRIPTPATH}"
cd "${SCRIPTPATH}/site"
npm run serve &
pids[2]=$!
cd "${SCRIPTPATH}"

echo "Visit site at http://10.0.0.1:8456"

for pid in ${pids[*]}; do
  wait $pid
done

