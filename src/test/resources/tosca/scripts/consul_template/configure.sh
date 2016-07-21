#!/bin/bash -e

CONF_PATH="/etc/consul_template"

sudo cp -f $config/index.html /usr/share/nginx/html/
sudo cp -f $config/nginx.default /etc/nginx/sites-enabled/default
sudo sed -i -e "s/%LISTEN_PORT%/${LISTEN_PORT}/g" /etc/nginx/sites-enabled/default
sudo sed -i -e "s/%SERVICE_PORT%/${SERVICE_PORT}/g" /etc/nginx/sites-enabled/default
sudo sed -i -e "s/%SERVER_NAME%/${SERVER_NAME}/g" /etc/nginx/sites-enabled/default

# generate the nginx config template
TEMPLATE_PATH="${CONF_PATH}/nginx.conf.ctpl"
sudo cp $config/nginx.conf.ctpl $TEMPLATE_PATH
sudo sed -i -e "s/%LISTEN_PORT%/${LISTEN_PORT}/g" $TEMPLATE_PATH
sudo sed -i -e "s/%SERVICE_PORT%/${SERVICE_PORT}/g" $TEMPLATE_PATH
sudo sed -i -e "s/%SERVER_NAME%/${SERVER_NAME}/g" $TEMPLATE_PATH

if [ "$TLS_ENABLED" == "true" ]; then
	SSL_REPO=$CONF_PATH/ssl
	# Generate a keypair for the client, and sign it with the CA
	sudo cp $ssl/ca.pem $SSL_REPO/ca.pem
	sudo openssl genrsa -out $SSL_REPO/client-key.pem 4096
	sudo openssl req -subj "/CN=alien4cloud.org" -sha256 -new -key $SSL_REPO/client-key.pem -out server.csr
	sudo echo "[ ssl_client ]" > extfile.cnf
	#sudo echo "subjectAltName=IP:127.0.0.1" >> extfile.cnf 
	sudo echo "extendedKeyUsage=serverAuth,clientAuth" >> extfile.cnf
	sudo openssl x509 -req -days 365 -sha256 \
		-in server.csr -CA $SSL_REPO/ca.pem -CAkey $ssl/ca-key.pem \
		-CAcreateserial -out $SSL_REPO/client-cert.pem \
		-passin pass:${CA_PASSPHRASE} \
		-extfile extfile.cnf -extensions ssl_client
fi

# evaluate and put the consul-template config
eval "echo \"$(< $config/consul_template.conf)\"" | sudo more > $CONF_PATH/consul_template.conf
echo "Content of $CONF_PATH/consul_template.conf"
cat $CONF_PATH/consul_template.conf