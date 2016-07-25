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
download "Alien4Cloud" "${APPLICATION_URL}" /tmp/alien4cloud/alien.war
sudo cp /tmp/alien4cloud/alien.war /opt/alien4cloud/alien.war

# add config
echo "Adding config files"
sudo unzip -qo /tmp/alien4cloud/alien.war -d /tmp/alien4cloud/
sudo jar -xf /tmp/alien4cloud/WEB-INF/lib/alien4cloud-rest-api-$ALIEN_VERSION.jar alien4cloud-config.yml
sudo mv alien4cloud-config.yml /etc/alien4cloud/
sudo cp /tmp/alien4cloud/WEB-INF/classes/log4j.properties /etc/alien4cloud/
sudo rm -rf /tmp/alien4cloud

# add the appropriate user
echo "Change folder ownership"
sudo chown -R alien4cloud:alien4cloud /var/log/alien4cloud
sudo chown -R alien4cloud:alien4cloud /opt/alien4cloud
sudo chown -R alien4cloud:alien4cloud /etc/alien4cloud

# add init script and start service
echo "Preparing services"
sudo bash -c "sed -e 's/\\\${APP_ARGS}/${APP_ARGS}/' $bin/alien.sh > /etc/init.d/alien"
sudo bash -c "sed -i -e 's/\\\${JVM_ARGS}/${JVM_ARGS}/' /etc/init.d/alien"

sudo chmod +x /etc/init.d/alien

sudo update-rc.d alien defaults 95 10
