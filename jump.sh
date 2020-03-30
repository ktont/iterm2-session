#!/usr/bin/env bash
prefix=`readlink "$0"`
if [ -n "$prefix" ]; then
    prefix=`dirname "$prefix"`
else
    prefix=`dirname "$0"`
    prefix=`cd "$prefix"; pwd`
fi

if [ $# -ne 1 ]; then
    echo "no input"
    exit 1
fi

if ! [ -f "$1" ]; then
    echo "no such file '$1'"
    exit 1
fi

if ! [ -s "$1" ]; then
    echo "empty input"
    exit 1
fi

ret=`grep -v '^[[:blank:]]*#' "$1" | ${prefix}/libraries/JSON.sh/JSON.sh -p -l`
err=$?
if [ $err -eq 1 ]; then
    echo "json invalid"
    exit $err
fi
ret=`echo "$ret" | awk -f ${prefix}/libraries/serialization.awk`
err=$?
if [ $err -eq 1 ]; then
    echo "$ret"
    exit $err
fi

PARAMS=()
eval "$ret"
#declare -p PARAMS

if [ "${PARAMS[1]}" -eq 1 ]; then
  LC_CTYPE=en_US \
  expect ${prefix}/libraries/jump.exp "${PARAMS[@]}"
else
  expect ${prefix}/libraries/jump.exp "${PARAMS[@]}"
fi

