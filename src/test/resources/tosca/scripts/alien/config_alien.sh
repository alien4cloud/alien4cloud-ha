#!/bin/bash
es_list=$(</tmp/a4c/work/${NODE}/es_list)

# set the alien port
sudo sed -i -e "s/port\: \(.*\)/port\: $ALIEN_PORT/g" /etc/alien4cloud/alien4cloud-config.yml
echo "The elastic list is $es_list"
# set the elsaticsearch hosts
sudo sed -i -e "s/hosts\: \(.*\)/hosts\: $es_list/g" /etc/alien4cloud/alien4cloud-config.yml
# set the alien IP for consul checks
sudo sed -i -e "s/instanceIp\: \(.*\)/instanceIp\: $ALIEN_IP/g" /etc/alien4cloud/alien4cloud-config.yml
# set the DNS service name
sudo sed -i -e "s/dnsServiceName\: \(.*\)/dnsServiceName\: $DNS_SERVICE_NAME/g" /etc/alien4cloud/alien4cloud-config.yml


