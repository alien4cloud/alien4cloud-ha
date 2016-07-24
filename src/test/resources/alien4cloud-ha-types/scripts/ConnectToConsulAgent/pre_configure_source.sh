#!/bin/bash -e 
source $commons/commons.sh
source $commons/ssl.sh

require_envs "AGENT_API_PORT AGENT_IP"
# check dependencies
require_bin "openssl"

# a node which is connected to consult will look in this folder
mkdir -p /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent
echo "${AGENT_API_PORT}" > /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/agentAPIPort
echo "${AGENT_IP}" > /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/agentIp
echo "${TLS_ENABLED}" > /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/TLSEnabled

if [ "$TLS_ENABLED" != "true" ]; then
	exit 0
fi

require_envs "CA_PASSPHRASE"

SOURCE_SSL_DIR="/tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/ssl"
mkdir -p "${SOURCE_SSL_DIR}"

SSL_DIR=$( generateKeyAndStore "alient4cloud.org" "client" "changeit" )
echo "changeit" > /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/storePwd
echo "client" > /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/alias

echo "Generated ssl folder ${SSL_DIR} contains: $(ls ${SSL_DIR})"
echo "Copying ${SSL_DIR} content into ${SOURCE_SSL_DIR}"
sudo cp ${SSL_DIR}/* ${SOURCE_SSL_DIR}/
sudo rm -rf ${SSL_DIR}

# CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# echo "Currently in $CURRENT_DIR"

# # FIXME: why ?
# KEY_PWD="${KEYSTORE_PWD}"
# require_envs "KEY_STORE_PATH TRUST_STORE_PATH KEYSTORE_PWD KEY_PWD"

# DIR=$(dirname "${KEY_STORE_PATH}")
# if [ ! -d $DIR ]; then
#   sudo mkdir -p $DIR
# fi
# DIR=$(dirname "${TRUST_STORE_PATH}")
# if [ ! -d $DIR ]; then
#   sudo mkdir -p $DIR
# fi

# TEMP_DIR=`mktemp -d` && cd $TEMP_DIR
# echo "working in temporary directory $TEMP_DIR"


# # IN: 
# #	- client-keystore.p12
# # - 
# # OUT:
# # - client-keystore.jks
# # all this is java relateds


# # IN: 
# #	- ca.pem
# # - 
# # OUT:
# # - ca.der
# # all this is java relateds
# # generate trust store
# echo "Generating truststore"


# sudo cp $TEMP_DIR/truststore.jks ${TRUST_STORE_PATH}
# sudo cp $TEMP_DIR/client-keystore.jks ${KEY_STORE_PATH}

# cd $CURRENT_DIR
# echo "will delete temp dir $TEMP_DIR"
# #rm -rf $TEMP_DIR
