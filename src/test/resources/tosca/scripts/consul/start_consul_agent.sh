#!/bin/bash -e

# evaluate and put the basic config
eval "echo \"$(< $configs/basic_config.json)\"" | sudo more > /etc/consul/01_basic_config.json
echo "Content of /etc/consul/01_basic_config.json"
cat /etc/consul/01_basic_config.json

if [ "$CONSUL_AGENT_MODE" == "server" ]; then
  	BOOTSTRAP_EXPECT=$(echo ${INSTANCES} | tr ',' ' ' | wc -w)
	# evaluate and put the server config
    eval "echo \"$(< ${configs}/server_config.json)\"" | sudo more > /etc/consul/02_server_config.json
	echo "Content of /etc/consul/02_server_config.json"
	cat /etc/consul/02_server_config.json
fi

if [ ! -z "$ENCRYPT_KEY" ]; then
    eval "echo \"$(< ${configs}/encrypt_config.json)\"" | sudo more > /etc/consul/03_encrypt_config.json
	echo "Content of /etc/consul/03_encrypt_config.json"
	cat /etc/consul/03_encrypt_config.json
fi

if [ "$TLS_ENABLED" == "true" ]; then
	# evaluate and put the secured config
    eval "echo \"$(< ${configs}/${CONSUL_AGENT_MODE}_secured_config.json)\"" | sudo more > /etc/consul/04_${CONSUL_AGENT_MODE}_secured_config.json
	echo "Content of /etc/consul/04_${CONSUL_AGENT_MODE}_secured_config.json"
	cat /etc/consul/04_${CONSUL_AGENT_MODE}_secured_config.json

	SSL_REPO=/etc/consul/ssl
	# Generate a keypair for the server or client, and sign it with the CA
	sudo cp $ssl/ca.pem $SSL_REPO/ca.pem
	sudo openssl genrsa -out $SSL_REPO/${CONSUL_AGENT_MODE}-key.pem 4096
	sudo openssl req -subj "/CN=alien4cloud.org" -sha256 -new -key $SSL_REPO/${CONSUL_AGENT_MODE}-key.pem -out server.csr
	sudo echo "[ ssl_client ]" > extfile.cnf
	# this cert will be used for the https api
	# since we use it only in local between client and consul client we bind it to 127.0.0.1
	sudo echo "subjectAltName = IP:127.0.0.1" >> extfile.cnf 
	sudo echo "extendedKeyUsage=serverAuth,clientAuth" >> extfile.cnf
	sudo openssl x509 -req -days 365 -sha256 \
		-in server.csr -CA $SSL_REPO/ca.pem -CAkey $ssl/ca-key.pem \
		-CAcreateserial -out $SSL_REPO/${CONSUL_AGENT_MODE}-cert.pem \
		-passin pass:${CA_PASSPHRASE} \
		-extfile extfile.cnf -extensions ssl_client
fi

echo "Start consul agent in ${CONSUL_AGENT_MODE} mode, expecting ${BOOTSTRAP_EXPECT} servers, data dir at ${CONSUL_DATA_DIR}, bind on interface ${CONSUL_BIND_ADDRESS}"

sudo nohup consul agent -config-dir /etc/consul > /var/log/consul/consul.log 2>&1 &

sleep 10
echo "Consul has following members until now"
sudo consul members

export CONSUL_SERVER_ADDRESS=${CONSUL_BIND_ADDRESS}:8301
export CONSUL_CLIENT_ADDRESS=${CONSUL_BIND_ADDRESS}:8500