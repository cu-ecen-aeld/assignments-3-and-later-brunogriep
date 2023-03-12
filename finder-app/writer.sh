#!/bin/sh
# Author: Bruno Griep Fernandes

writestr=$(basename "$1")
dir=$(dirname "$1")
if [ -z "$writestr" ]; then
  echo "writestr (arg1) not specified. Please fix it"
  return 1
else
  if [ ! -d "$dir" ]; then
    echo "The directory \"$dir\" does not exist... Creating it"
    mkdir -p "$dir"
  fi
fi

if [ -z "$2" ]; then
  echo "searchstr (arg2) not specified. Please fix it"
  return 1
fi

echo "Writing \"$2\" to the file \"$1\""
echo "$2" >"$1"
