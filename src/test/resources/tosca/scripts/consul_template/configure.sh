#!/bin/bash -e
sudo cp $config/nginx.conf.ctpl /etc/consul_template/
sudo sed -i -e "s/%LISTEN_PORT%/${LISTEN_PORT}/g" $CONF_PATH
sudo sed -i -e "s/%SERVICE_PORT%/${SERVICE_PORT}/g" $CONF_PATH
sudo sed -i -e "s/%SERVER_NAME%/${SERVER_NAME}/g" $CONF_PATH
