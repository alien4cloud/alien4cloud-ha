#!/bin/bash -e
source $commons/commons.sh
# check required binaries
require_bin wget
# install packages if need
install_dependencies unzip

sudo mkdir -p /etc/consul_template/ssl
sudo mkdir -p /var/lib/consul_template/
sudo mkdir -p /var/log/consul_template/

# TODO: use a function
wget --quiet -O /tmp/consul-template.zip "${APPLICATION_URL}"
sudo unzip /tmp/consul-template.zip -d /var/lib/consul_template/
