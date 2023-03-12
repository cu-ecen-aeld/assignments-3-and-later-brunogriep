#!/bin/sh
# Author: Bruno Griep Fernandes

if [ -z "$1" ]; then
  echo "filesdir (arg1) not specified. Please fix it"
  return 1
else
  if [ ! -d "$1" ]; then
    echo "The directory \"$1\" does not exist."
    return 1
  fi
fi

if [ -z "$2" ]; then
  echo "searchstr (arg2) not specified. Please fix it"
  return 1
fi

X=$(find $1 -type f | wc -l)
Z=$(grep -hnr $2 $1 | wc -l)
echo "The number of files are ${X} and the number of matching lines are ${Z}"
