#!/bin/bash -e

if [ "$CONSUL_AGENT_MODE" == "server" ]; then
  	SERVER_MODE="-server"
  	nb_masters=$((0))
  	for master in $(echo ${INSTANCES} | tr ',' ' ')
    do
      nb_masters=$((nb_masters + 1))
    done  
  	BOOTSTRAP_EXPECT="-bootstrap-expect ${nb_masters}"
fi
echo "Start consul agent in ${CONSUL_AGENT_MODE} mode, expecting ${nb_masters} servers, data dir at ${CONSUL_DATA_DIR}, bind on interface ${CONSUL_BIND_ADDRESS}"

sudo nohup consul agent ${SERVER_MODE} ${BOOTSTRAP_EXPECT} \
  -data-dir ${CONSUL_DATA_DIR} \
  -bind ${CONSUL_BIND_ADDRESS} \
  -client 0.0.0.0 >/tmp/consul.log 2>&1 &

# TODO Export the consul address by using consul members for later injection, for now we'll use default static address

echo "Consul has following members until now"

sleep 10

sudo consul members

export CONSUL_SERVER_ADDRESS=${CONSUL_BIND_ADDRESS}:8301
export CONSUL_CLIENT_ADDRESS=${CONSUL_BIND_ADDRESS}:8500