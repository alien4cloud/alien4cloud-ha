#!/bin/bash -e
source $commons/commons.sh

install_dependencies "unzip"
require_bin "jar"
require_envs "APPLICATION_URL DATA_DIR ALIEN_VERSION"

# create user
sudo useradd alien4cloud

# create log folder
echo "Make log dir"
if [ ! -d /var/log/alien4cloud ]; then
  sudo mkdir -p /var/log/alien4cloud
fi

echo "Make etc dir"
if [ ! -d /etc/alien4cloud ]; then
  sudo mkdir -p /etc/alien4cloud
fi

echo "Make tmp dir"
if [ ! -d /tmp/alien4cloud ]; then
	sudo mkdir -p /tmp/alien4cloud
fi

# create application folder
echo "Make opt dir"
if [ ! -d /opt/alien4cloud ]; then
  sudo mkdir -p /opt/alien4cloud
fi

# create data folder
echo "Make data dir $DATA_DIR"
if [ ! -d $DATA_DIR ]; then
  sudo mkdir -p $DATA_DIR
fi

# download files
download "Alien4Cloud" "${APPLICATION_URL}" /tmp/alien4cloud/alien4cloud-premium-dist.tar.gz
sudo tar -xzf /tmp/alien4cloud/alien4cloud-premium-dist.tar.gz -C /opt/alien4cloud

# add config
sudo rm -rf /tmp/alien4cloud

# add the appropriate user
echo "Change folder ownership"
sudo chown -R alien4cloud:alien4cloud /opt/alien4cloud

