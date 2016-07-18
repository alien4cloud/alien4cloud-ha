#!/bin/bash -e

echo "Installing Alien4Cloud"

# create user
sudo useradd alien4cloud

# create log folder
echo "Make log dir"
if [ ! -d /var/log/alien4cloud ]; then
  sudo mkdir /var/log/alien4cloud
fi

echo "Make etc dir"
if [ ! -d /etc/alien4cloud ]; then
  sudo mkdir /etc/alien4cloud
fi

echo "Make tmp dir"
if [ ! -d /tmp/alien4cloud ]; then
	sudo mkdir /tmp/alien4cloud
fi

# create application folder and copie files
echo "Download webapp from ${APPLICATION_URL}"
sudo wget --quiet -O /tmp/alien4cloud/alien.war "${APPLICATION_URL}"
echo "Make opt dir"
if [ ! -d /opt/alien4cloud ]; then
  sudo mkdir /opt/alien4cloud
fi
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
sudo chmod +x /etc/init.d/alien

sudo update-rc.d alien defaults 95 10
