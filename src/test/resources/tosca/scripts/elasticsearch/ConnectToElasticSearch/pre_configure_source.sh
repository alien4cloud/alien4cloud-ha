#!/bin/bash -e
instance_id=0
es_list=""
IFS=',';
for i in $TARGET_INSTANCES;
do
  # TODO: remove if not uning TDK
  #varname="${SOURCE_INSTANCE}_${i}_ES_IP";
  varname="${i}_ES_IP";
  if [ ${instance_id} -eq 0 ]
    then
      es_list="${!varname}:${ES_PORT}"
    else
      es_list="${es_list},${!varname}:${ES_PORT}"
  fi
  instance_id=$((instance_id+1))
done
mkdir -p /tmp/a4c/work/${SOURCE_NODE}/
echo "${es_list}" > /tmp/a4c/work/${SOURCE_NODE}/es_list
