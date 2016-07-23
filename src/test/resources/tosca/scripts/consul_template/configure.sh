#!/bin/bash -e

CONF_PATH="/etc/consul_template"

# check dependencies
command -v openssl >/dev/null 2>&1 || { echo "I require openssl but it's not installed.  Aborting." >&2; exit 1; }

# generate the nginx config template
TEMPLATE_PATH="${CONF_PATH}/nginx.conf.ctpl"
sudo cp $config/nginx.conf.ctpl $TEMPLATE_PATH
sudo sed -i -e "s/%SERVICE_PORT%/${SERVICE_PORT}/g" $TEMPLATE_PATH
sudo sed -i -e "s/%SERVER_NAME%/${SERVER_NAME}/g" $TEMPLATE_PATH
if [ "$TARGET_PROTOCOL" == "https" ]; then
	sudo sed -i -e "s/%LISTEN_PORT%/${LISTEN_PORT} ssl/g" $TEMPLATE_PATH
	sudo sed -i -e "s/%PROTOCOL%/https/g" $TEMPLATE_PATH
else
	sudo sed -i -e "s/%LISTEN_PORT%/${LISTEN_PORT}/g" $TEMPLATE_PATH
	sudo sed -i -e "s/%PROTOCOL%/http/g" $TEMPLATE_PATH
fi

if [ "$TLS_ENABLED" == "true" ]; then
	TEMP_DIR=`mktemp -d`
	SSL_REPO=$CONF_PATH/ssl
	# Generate a keypair for the client, and sign it with the CA
	sudo cp $ssl/ca.pem $SSL_REPO/ca.pem
	sudo openssl genrsa -out $SSL_REPO/client-key.pem 4096
	sudo openssl req -subj "/CN=alien4cloud.org" -sha256 -new -key $SSL_REPO/client-key.pem -out $TEMP_DIR/server.csr
	sudo echo "[ ssl_client ]" > $TEMP_DIR/extfile.cnf
	#sudo echo "subjectAltName=IP:127.0.0.1" >> extfile.cnf
	sudo echo "extendedKeyUsage=serverAuth,clientAuth" >> $TEMP_DIR/extfile.cnf
	sudo openssl x509 -req -days 365 -sha256 \
		-in $TEMP_DIR/server.csr -CA $SSL_REPO/ca.pem -CAkey $ssl/ca-key.pem \
		-CAcreateserial -out $SSL_REPO/client-cert.pem \
		-passin pass:${CA_PASSPHRASE} \
		-extfile $TEMP_DIR/extfile.cnf -extensions ssl_client
fi

# evaluate and put the consul-template config
sudo cp $config/consul_template.conf $CONF_PATH/consul_template.conf
sudo sed -i -e "s/%TLS_ENABLED%/${TLS_ENABLED}/g" $CONF_PATH/consul_template.conf

echo "Content of $CONF_PATH/consul_template.conf"
sudo cat $CONF_PATH/consul_template.conf
