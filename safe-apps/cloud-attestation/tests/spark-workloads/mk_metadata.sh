#!/bin/bash

datadir=data
datahome="${datadir}/$1"

main() {
  if [ $# -ne 1 ]; then
    usage
    exit 1
  fi
 
  if [ ! -e ${datahome} ]; then
    echo "Data subdirectory ${datahome} not found!"
    exit 1
  fi
  
  extract_metadata
}

usage() {
  echo "Usage: $0 <data-subdirectory-under-data>"
}

extract_metadata() {
  fileofdriver="${datahome}/driver_id.txt"
  fileofexecutors="${datahome}/exec_ids.txt"
  echo "datahome: ${datahome}"
  allfiles="${datahome}/*_global.json"
#  for f in "${datahome}/*"; do  # this doesn't work
  for f in ${allfiles}; do
#    echo "$f"
#    echo "${f##*/}"
    filename=${f##*/}
    echo "filename: ${filename}"
    pid=`echo ${filename} | sed -n -e "s/^req.\(.*\)_.*/\1/p"`
    echo "pid: ${pid}"
    driver_req="${datahome}/req.${pid}__spark-kubernetes-driver.json"
    exec_req="${datahome}/req.${pid}__executor.json"
    if [ -e ${driver_req} ]; then
      echo "Driver: ${driver_req}"
      echo "$pid" >> "${fileofdriver}"
    else
      if [ -e ${exec_req} ]; then
        echo "Executor: ${exec_req}"
        echo "$pid" >> "${fileofexecutors}"
      fi
    fi
  done
}

main "$@"