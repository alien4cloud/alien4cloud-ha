#!/bin/bash

# get the ES address list
es_list=$(</tmp/a4c/work/${NODE}/es_list)

# enable HA if more than 1 instance found
number_of_instances=$(echo ${INSTANCES} | tr ',' ' ' | wc -w)
if [ "${number_of_instances}" -gt "1" ]; then
  sudo sed -i -e "s/ha_enabled\: \(.*\)/ha_enabled\: true/g" /etc/alien4cloud/alien4cloud-config.yml
else
  sudo sed -i -e "s/ha_enabled\: \(.*\)/ha_enabled\: false/g" /etc/alien4cloud/alien4cloud-config.yml
fi

# set the alien port
sudo sed -i -e "s/port\: \(.*\)/port\: $ALIEN_PORT/g" /etc/alien4cloud/alien4cloud-config.yml
echo "The elastic list is $es_list"
# set the elsaticsearch hosts
sudo sed -i -e "s/hosts\: \(.*\)/hosts\: $es_list/g" /etc/alien4cloud/alien4cloud-config.yml
# set the alien IP for consul checks
sudo sed -i -e "s/instanceIp\: \(.*\)/instanceIp\: $ALIEN_IP/g" /etc/alien4cloud/alien4cloud-config.yml
# set the DNS service name
sudo sed -i -e "s/dnsServiceName\: \(.*\)/dnsServiceName\: $DNS_SERVICE_NAME/g" /etc/alien4cloud/alien4cloud-config.yml
