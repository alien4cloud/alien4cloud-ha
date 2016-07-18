#!/bin/bash -e
sudo cp $config/nginx.conf $CONF_PATH
sudo sed -i -e "s/%LISTEN_PORT%/${LISTEN_PORT}/g" $CONF_PATH
sudo sed -i -e "s/%SERVICE_FQN%/${SERVICE_FQN}/g" $CONF_PATH
sudo sed -i -e "s/%SERVICE_PORT%/${SERVICE_PORT}/g" $CONF_PATH