#!/bin/bash
source $commons/commons.sh
require_envs "AGENT_API_PORT AGENT_IP"
# check dependencies
require_bin "openssl keytool"

# just a flag to know that we are connected to a consul agent
echo "true" > /tmp/a4c/work/${SOURCE_NODE}/connectedToConsulAgent
mkdir -p /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent
echo "${AGENT_API_PORT}" > /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/agentAPIPort
echo "${AGENT_IP}" > /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/agentIp
echo "${TLS_ENABLED}" > /tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/TLSEnabled

if [ "$TLS_ENABLED" != "true" ]; then
	exit 0
fi

SOURCE_SSL_DIR="/tmp/a4c/work/${SOURCE_NODE}/ConnectToConsulAgent/ssl"
mkdir -p "${SOURCE_SSL_DIR}"

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "Currently in $CURRENT_DIR"

# FIXME: why ?
KEY_PWD="${KEYSTORE_PWD}"
require_envs "KEY_STORE_PATH TRUST_STORE_PATH KEYSTORE_PWD KEY_PWD"

DIR=$(dirname "${KEY_STORE_PATH}")
if [ ! -d $DIR ]; then
  sudo mkdir -p $DIR
fi
DIR=$(dirname "${TRUST_STORE_PATH}")
if [ ! -d $DIR ]; then
  sudo mkdir -p $DIR
fi

TEMP_DIR=`mktemp -d` && cd $TEMP_DIR
echo "working in temporary directory $TEMP_DIR"

echo "Generate client key"
openssl genrsa -out ${SOURCE_SSL_DIR}/client-key.pem 4096
openssl req -subj "/CN=alien4cloud.org" -sha256 -new -key ${SOURCE_SSL_DIR}/client-key.pem -out $TEMP_DIR/client.csr
# Sign the key with the CA
echo "[ ssl_client ]" > $TEMP_DIR/extfile.cnf
echo "extendedKeyUsage=serverAuth,clientAuth" >> $TEMP_DIR/extfile.cnf
openssl x509 -req -days 365 -sha256 \
        -in $TEMP_DIR/client.csr -CA $ssl/ca.pem -CAkey $ssl/ca-key.pem \
        -CAcreateserial -out ${SOURCE_SSL_DIR}/client-cert.pem \
        -passin pass:$CA_PASSPHRASE \
        -extfile $TEMP_DIR/extfile.cnf -extensions ssl_client

# poulate key store
echo "Generate client keystore using openssl"
openssl pkcs12 -export -name alien4cloudClient \
		-in ${SOURCE_SSL_DIR}/client-cert.pem -inkey ${SOURCE_SSL_DIR}/client-key.pem \
		-out $TEMP_DIR/client-keystore.p12 -chain \
		-CAfile $ssl/ca.pem -caname root \
		-password pass:$KEYSTORE_PWD



echo "Using keytoool to generate a jks client keystore"
keytool -importkeystore -destkeystore $TEMP_DIR/client-keystore.jks \
		-srckeystore $TEMP_DIR/client-keystore.p12 -srcstoretype pkcs12 \
		-alias alien4cloudClient -deststorepass $KEYSTORE_PWD \
		-srckeypass $KEY_PWD -srcstorepass $KEYSTORE_PWD 2>&1
ensure_success "Using keytoool to generate a jks client keystore"

# generate trust store
echo "Generating truststore"
openssl x509 -outform der -in $ssl/ca.pem -out $TEMP_DIR/ca.der
keytool -import -alias alien4cloud -keystore $TEMP_DIR/truststore.jks \
		-file $TEMP_DIR/ca.der -storepass $KEYSTORE_PWD -noprompt

sudo cp $TEMP_DIR/truststore.jks ${TRUST_STORE_PATH}
sudo cp $TEMP_DIR/client-keystore.jks ${KEY_STORE_PATH}

cd $CURRENT_DIR
echo "will delete temp dir $TEMP_DIR"
#rm -rf $TEMP_DIR
