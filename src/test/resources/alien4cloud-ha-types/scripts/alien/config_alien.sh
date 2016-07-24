#!/bin/bash -e
source $commons/commons.sh

require_envs "DATA_DIR SERVER_PROTOCOL ALIEN_PORT"

A4C_CONFIG="/etc/alien4cloud/alien4cloud-config.yml"

CONNECTED_TO_CONSUL="false"
if [ ! -d "/tmp/a4c/work/${NODE}/ConnectToConsulAgent" ]; then
  CONNECTED_TO_CONSUL="true"
  AGENT_API_PORT=$(</tmp/a4c/work/${NODE}/ConnectToConsulAgent/agentAPIPort)
  AGENT_IP=$(</tmp/a4c/work/${NODE}/ConnectToConsulAgent/agentIp)
fi

# replace the alien data dir
echo "A4C data dir is ${DATA_DIR}"
sudo sed -i -e "s@alien\: \(.*\)@alien\: ${DATA_DIR}@g" ${A4C_CONFIG}
# set the alien port
sudo sed -i -e "s/port\: \(.*\)/port\: $ALIEN_PORT/g" ${A4C_CONFIG}
# set the alien protocol
sudo sed -i -e "s/serverProtocol\: \(.*\)/serverProtocol\: $SERVER_PROTOCOL/g" ${A4C_CONFIG}

if [ "$SERVER_PROTOCOL" == "https" ]; then
  # enable SSL
  sudo sed -i -e "s/#ssl\:/ssl\:/g" ${A4C_CONFIG}

  # FIXME: can't be different !!! some confusion somewhere ?
  SERVER_KEYSTORE_PWD="changeit"
  KEY_PWD="${SERVER_KEYSTORE_PWD}"

  AC4_SSL_DIR=/etc/alien4cloud/ssl
  sudo mkdir -p $AC4_SSL_DIR

  TEMP_DIR=`mktemp -d`
  # TODO: use commons ssl
  # Generate a keypair for the server or client, and sign it with the CA
  sudo openssl genrsa -out $TEMP_DIR/server-key.pem 4096
  sudo openssl req -subj "/CN=alien4cloud.org" -sha256 -new -key $TEMP_DIR/server-key.pem -out $TEMP_DIR/server.csr
  # this cert will be used for the https api
  sudo echo "subjectAltName = IP:${ALIEN_IP}" > $TEMP_DIR/extfile.cnf
  sudo openssl x509 -req -days 365 -sha256 \
    -in $TEMP_DIR/server.csr -CA $ssl/ca.pem -CAkey $ssl/ca-key.pem \
    -CAcreateserial -out $TEMP_DIR/server-cert.pem \
    -passin pass:${CA_PASSPHRASE} \
    -extfile $TEMP_DIR/extfile.cnf

  # poulate key store
  sudo openssl pkcs12 -export -name alien4cloudClient \
    -in $TEMP_DIR/server-cert.pem -inkey $TEMP_DIR/server-key.pem \
    -out $TEMP_DIR/server-keystore.p12 -chain \
    -CAfile $ssl/ca.pem -caname root \
    -password pass:$SERVER_KEYSTORE_PWD

  sudo keytool -importkeystore -destkeystore $AC4_SSL_DIR/server-keystore.jks \
    -srckeystore $TEMP_DIR/server-keystore.p12 -srcstoretype pkcs12 \
    -alias alien4cloudClient -deststorepass $SERVER_KEYSTORE_PWD \
    -srckeypass $KEY_PWD -srcstorepass $SERVER_KEYSTORE_PWD

  sudo rm -rf $TEMP_DIR

  sudo sed -i -e "s@#  key-store\: \(.*\)@  key-store\: \"$AC4_SSL_DIR/server-keystore.jks\"@g" ${A4C_CONFIG}
  sudo sed -i -e "s/#  key-store-password\: \(.*\)/  key-store-password\: \"$SERVER_KEYSTORE_PWD\"/g" ${A4C_CONFIG}
  sudo sed -i -e "s/#  key-password\: \(.*\)/  key-password\: \"$KEY_PWD\"/g" ${A4C_CONFIG}
fi

# get the ES address list
es_list=$(</tmp/a4c/work/${NODE}/es_list)

if [ -z "$es_list" ]; then
  echo "Not connected to any ES cluster"
  sudo sed -i -e "s/client\: \(.*\)/client\: false/g" ${A4C_CONFIG}
  sudo sed -i -e "s/transportClient\: \(.*\)/transportClient\: false/g" ${A4C_CONFIG}
  exit 0
fi

echo "A4C is connected to remote ElasticSearch ${es_list}"
sudo sed -i -e "s/client\: \(.*\)/client\: true/g" ${A4C_CONFIG}
sudo sed -i -e "s/transportClient\: \(.*\)/transportClient\: true/g" ${A4C_CONFIG}

# get the cluster name
cluster_name=$(</tmp/a4c/work/${NODE}/cluster_name)
echo "The ElasticSearch cluster is: ${cluster_name}"
# replace the cluster name in alien config
sudo sed -i -e "s/clusterName\: \(.*\)/clusterName\: $cluster_name/g" ${A4C_CONFIG}
sudo bash -c 'echo "cluster.name: ${cluster_name}" > /etc/alien4cloud/elasticsearch.yml'

## FIXME: enabling the HA should not be related to the number of A4C instances ...
## ... but instead to the fact that we are actually connected to consul
#number_of_instances=$(echo ${INSTANCES} | tr ',' ' ' | wc -w)
# enable HA if A4C is connected to a Consul agent
if [ -d "/tmp/a4c/work/${NODE}/ConnectToConsulAgent" ]; then
  AGENT_API_PORT=$(</tmp/a4c/work/${NODE}/ConnectToConsulAgent/agentAPIPort)
  AGENT_IP=$(</tmp/a4c/work/${NODE}/ConnectToConsulAgent/agentIp)

  echo "A4C is connected to Consul ${AGENT_IP}:{AGENT_API_PORT}, activate HA"
  sudo sed -i -e "s/ha_enabled\: \(.*\)/ha_enabled\: true/g" ${A4C_CONFIG}
  sudo sed -i -e "s/consulAgentIp\: \(.*\)/consulAgentIp\: ${AGENT_IP}/g" ${A4C_CONFIG}
  sudo sed -i -e "s/consulAgentPort\: \(.*\)/consulAgentPort\: ${AGENT_API_PORT}/g" ${A4C_CONFIG}
  sudo sed -i -e "s/#\(.*\)consulAgentIp\: \(.*\)/consulAgentIp\: ${AGENT_IP}/g" ${A4C_CONFIG}
  sudo sed -i -e "s/#\(.*\)consulAgentPort\: \(.*\)/consulAgentPort\: ${AGENT_API_PORT}/g" ${A4C_CONFIG}

  TLS_ENABLED=$(</tmp/a4c/work/${NODE}/ConnectToConsulAgent/TLSEnabled)
  if [ "$TLS_ENABLED" == "true" ]; then

      require_bin "keytool"

      SSL_STORE_PATH="/etc/alien4cloud/consul/ssl"
      sudo mkdir -p $SSL_STORE_PATH
      SSL_DIR="/tmp/a4c/work/${NODE}/ConnectToConsulAgent/ssl"

      KEY_ALIAS=$(</tmp/a4c/work/${NODE}/ConnectToConsulAgent/alias)
      STORE_PWD=$(</tmp/a4c/work/${NODE}/ConnectToConsulAgent/storePwd)

      # here we need to create java compliant keystores ...
      echo "Using keytoool to generate a jks client keystore"
      sudo keytool -importkeystore -destkeystore $SSL_STORE_PATH/client-keystore.jks \
          -srckeystore $SSL_DIR/$KEY_ALIAS-keystore.p12 -srcstoretype pkcs12 \
          -alias ${KEY_ALIAS} -deststorepass "${STORE_PWD}" \
          -srckeypass "${STORE_PWD}" -srcstorepass "${STORE_PWD}" 2>&1
      ensure_success "Using keytoool to generate a jks client keystore"

      sudo keytool -import -alias ${KEY_ALIAS} -keystore $SSL_STORE_PATH/truststore.jks \
          -file $SSL_DIR/ca.csr -storepass "${STORE_PWD}" -noprompt

      # FIXME: for the moment the securised client agent only listen on 127.0.0.1
      sudo sed -i -e "s/consulAgentIp\: \(.*\)/consulAgentIp\: 127.0.0.1/g" ${A4C_CONFIG}
      sudo sed -i -e "s/consul_tls_enabled\: \(.*\)/consul_tls_enabled\: true/g" ${A4C_CONFIG}
      sudo sed -i -e "s@keyStorePath\: \(.*\)@keyStorePath\: $SSL_STORE_PATH/client-keystore.jks@g" ${A4C_CONFIG}
      sudo sed -i -e "s@trustStorePath\: \(.*\)@trustStorePath\: $SSL_STORE_PATH/truststore.jks@g" ${A4C_CONFIG}
      sudo sed -i -e "s/keyStoresPwd\: \(.*\)/keyStoresPwd\: changeit/g" ${A4C_CONFIG}
  else
      sudo sed -i -e "s/consul_tls_enabled\: \(.*\)/consul_tls_enabled\: false/g" ${A4C_CONFIG}
  fi
else
  echo "A4C is not connected to Consul, desactivate HA"
  sudo sed -i -e "s/ha_enabled\: \(.*\)/ha_enabled\: false/g" ${A4C_CONFIG}
fi

# set the elsaticsearch hosts
sudo sed -i -e "s/hosts\: \(.*\)/hosts\: $es_list/g" ${A4C_CONFIG}
# set the alien IP for consul checks
sudo sed -i -e "s/instanceIp\: \(.*\)/instanceIp\: $ALIEN_IP/g" ${A4C_CONFIG}
