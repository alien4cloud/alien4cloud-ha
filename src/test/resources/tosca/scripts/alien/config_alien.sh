#!/bin/bash

A4C_CONFIG="/etc/alien4cloud/alien4cloud-config.yml"

# get the ES address list
es_list=$(</tmp/a4c/work/${NODE}/es_list)

if [ -z "$es_list" ]; then
  echo "Not connected to any ES cluster"
  sudo sed -i -e "s/client\: \(.*\)/client\: false/g" ${A4C_CONFIG}
  sudo sed -i -e "s/transportClient\: \(.*\)/transportClient\: false/g" ${A4C_CONFIG}
  exit 0
fi

echo "A4C is connected to remote ElasticSearch $es_list"
sudo sed -i -e "s/client\: \(.*\)/client\: true/g" ${A4C_CONFIG}
sudo sed -i -e "s/transportClient\: \(.*\)/transportClient\: true/g" ${A4C_CONFIG}

# get the cluster name
cluster_name=$(</tmp/a4c/work/${NODE}/cluster_name)
# replace the cluster name in alien config
sudo sed -i -e "s/clusterName\: \(.*\)/clusterName\: $cluster_name/g" ${A4C_CONFIG}

# enable HA if more than one A4C instance found
number_of_instances=$(echo ${INSTANCES} | tr ',' ' ' | wc -w)
if [ "${number_of_instances}" -gt "1" ]; then
  sudo sed -i -e "s/ha_enabled\: \(.*\)/ha_enabled\: true/g" ${A4C_CONFIG}
else
  sudo sed -i -e "s/ha_enabled\: \(.*\)/ha_enabled\: false/g" ${A4C_CONFIG}
fi

# set the alien port
sudo sed -i -e "s/port\: \(.*\)/port\: $ALIEN_PORT/g" ${A4C_CONFIG}
echo "The elastic list is $es_list"
# set the elsaticsearch hosts
sudo sed -i -e "s/hosts\: \(.*\)/hosts\: $es_list/g" ${A4C_CONFIG}
# set the alien IP for consul checks
sudo sed -i -e "s/instanceIp\: \(.*\)/instanceIp\: $ALIEN_IP/g" ${A4C_CONFIG}
