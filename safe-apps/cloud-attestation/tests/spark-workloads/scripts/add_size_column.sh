#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 <path-to-data-file> <column-value-to-add>"
  exit
fi

last_col=$2

while IFS= read -r line
do
  printf "$line ${last_col}\n"
done < $1
  