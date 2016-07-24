#!/bin/bash -e
source $commons/commons.sh

require_envs "CONSUL_DATA_DIR,INSTANCE,CONSUL_BIND_ADDRESS,CONSUL_API_PORT"

echo "Starting consul agent on ${CONSUL_BIND_ADDRESS}"

# evaluate and put the basic config
eval_conf_file $configs/basic_config.json /etc/consul/01_basic_config.json "CONSUL_DATA_DIR,INSTANCE,CONSUL_BIND_ADDRESS,CONSUL_API_PORT"

if [ "$CONSUL_AGENT_MODE" == "server" ]; then
  BOOTSTRAP_EXPECT=$(echo ${INSTANCES} | tr ',' ' ' | wc -w)
	# evaluate and put the server config
  eval_conf_file $configs/server_config.json /etc/consul/02_server_config.json "BOOTSTRAP_EXPECT"
fi

if [ ! -z "$ENCRYPT_KEY" ]; then
  eval_conf_file $configs/encrypt_config.json /etc/consul/03_encrypt_config.json "ENCRYPT_KEY"
fi

if [ "$TLS_ENABLED" == "true" ]; then

  TEMP_DIR=`mktemp -d`

	# evaluate and put the secured config
  eval_conf_file $configs/${CONSUL_AGENT_MODE}_secured_config.json /etc/consul/04_${CONSUL_AGENT_MODE}_secured_config.json "CONSUL_API_PORT"

	SSL_REPO=/etc/consul/ssl
	# Generate a keypair for the server or client, and sign it with the CA
	sudo cp $ssl/ca.pem $SSL_REPO/ca.pem
	sudo openssl genrsa -out $SSL_REPO/${CONSUL_AGENT_MODE}-key.pem 4096
	sudo openssl req -subj "/CN=alien4cloud.org" -sha256 -new -key $SSL_REPO/${CONSUL_AGENT_MODE}-key.pem -out $TEMP_DIR/server.csr
	sudo echo "[ ssl_client ]" > $TEMP_DIR/extfile.cnf
	# this cert will be used for the https api
	# since we use it only in local between client and consul client we bind it to 127.0.0.1
	sudo echo "subjectAltName = IP:127.0.0.1" >> $TEMP_DIR/extfile.cnf
	sudo echo "extendedKeyUsage=serverAuth,clientAuth" >> $TEMP_DIR/extfile.cnf
	sudo openssl x509 -req -days 365 -sha256 \
		-in $TEMP_DIR/server.csr -CA $SSL_REPO/ca.pem -CAkey $ssl/ca-key.pem \
		-CAcreateserial -out $SSL_REPO/${CONSUL_AGENT_MODE}-cert.pem \
		-passin pass:${CA_PASSPHRASE} \
		-extfile $TEMP_DIR/extfile.cnf -extensions ssl_client

  sudo rm -rf $TEMP_DIR
fi

echo "Start consul agent in ${CONSUL_AGENT_MODE} mode, expecting ${BOOTSTRAP_EXPECT} servers, data dir at ${CONSUL_DATA_DIR}, bind on interface ${CONSUL_BIND_ADDRESS}"

nohup sudo bash -c 'consul agent -config-dir /etc/consul > /var/log/consul/consul.log 2>&1 &' >> /dev/null 2>&1 &

sleep 10
echo "Consul has following members until now"
sudo consul members

# export API_PORT=:8500
# export CONSUL_SERVER_ADDRESS=${CONSUL_BIND_ADDRESS}:8301
# export CONSUL_CLIENT_ADDRESS=${CONSUL_BIND_ADDRESS}:${API_PORT}
