#!/bin/bash -e
source $commons/commons.sh
install_dependencies unzip

if [ ! -d "/etc/consul/ssl" ]; then
  sudo mkdir -p /etc/consul/ssl
fi
if [ ! -d "/var/log/consul" ]; then
  sudo mkdir -p /var/log/consul
fi
if [ ! -d "$CONSUL_DATA_DIR" ]; then
  sudo mkdir -p ${CONSUL_DATA_DIR}
fi

CONSUL_TMP_ZIP=/tmp/consul.zip

# TODO: use a funtion
curl -Lo ${CONSUL_TMP_ZIP} -O ${CONSUL_DOWNLOAD_URL}
echo "Downloaded consul binary from ${CONSUL_DOWNLOAD_URL} to temporary destination ${CONSUL_TMP_ZIP}"

sudo unzip -o ${CONSUL_TMP_ZIP} -d /usr/local/bin
echo "Unzipped consul package to /usr/local/bin"

rm ${CONSUL_TMP_ZIP}
