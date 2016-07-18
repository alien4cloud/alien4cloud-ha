#!/bin/bash -e
if [ -f $CONF_PATH ];
then
  sudo mv $CONF_PATH $CONF_PATH.back
fi
sudo cp $config/haproxy.cfg $CONF_PATH
sudo sed -i -e "s/%LISTEN_PORT%/${LISTEN_PORT}/g" $CONF_PATH
sudo sed -i -e "s/%SERVICE_FQN%/${SERVICE_FQN}/g" $CONF_PATH
sudo sed -i -e "s/%SERVICE_PORT%/${SERVICE_PORT}/g" $CONF_PATH
sudo sed -i -e "s/%SERVER_NAME%/${SERVER_NAME}/g" $CONF_PATH
