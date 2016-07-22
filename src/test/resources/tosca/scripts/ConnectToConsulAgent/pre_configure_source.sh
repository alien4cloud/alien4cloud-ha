#!/bin/bash

# just a flag to know that we are connected to a consul agent
mkdir -p /tmp/a4c/work/${SOURCE_NODE}/
echo "true" > /tmp/a4c/work/${SOURCE_NODE}/connectedToConsulAgent

if [ "$TLS_ENABLED" != "true" ]; then
	exit 0
fi

# check dependencies
command -v openssl >/dev/null 2>&1 || { echo "I require openssl but it's not installed.  Aborting." >&2; exit 1; }
command -v keytool >/dev/null 2>&1 || { echo "I require keytool but it's not installed.  Aborting." >&2; exit 1; }

CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "Currently in $CURRENT_DIR"

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

openssl genrsa -out client-key.pem 4096
openssl req -subj "/CN=alien4cloud.org" -sha256 -new -key client-key.pem -out client.csr
echo "[ ssl_client ]" > extfile.cnf
echo "extendedKeyUsage=serverAuth,clientAuth" >> extfile.cnf
openssl x509 -req -days 365 -sha256 \
        -in client.csr -CA $ssl/ca.pem -CAkey $ssl/ca-key.pem \
        -CAcreateserial -out client-cert.pem \
        -passin pass:$CA_PASSPHRASE \
        -extfile extfile.cnf -extensions ssl_client

# poulate key store
openssl pkcs12 -export -name alien4cloudClient \
		-in client-cert.pem -inkey client-key.pem \
		-out client-keystore.p12 -chain \
		-CAfile $ssl/ca.pem -caname root \
		-password pass:$KEYSTORE_PWD

keytool -importkeystore -destkeystore client-keystore.jks \
		-srckeystore client-keystore.p12 -srcstoretype pkcs12 \
		-alias alien4cloudClient -deststorepass $KEYSTORE_PWD \
		-srckeypass $KEY_PWD -srcstorepass $KEYSTORE_PWD

# generate trust store
openssl x509 -outform der -in $ssl/ca.pem -out ca.der
keytool -import -alias alien4cloud -keystore truststore.jks \
		-file ca.der -storepass $KEYSTORE_PWD -noprompt

sudo cp truststore.jks ${TRUST_STORE_PATH}
sudo cp client-keystore.jks ${KEY_STORE_PATH}

cd $CURRENT_DIR
echo "will delete temp dir $TEMP_DIR"
rm -rf $TEMP_DIR
