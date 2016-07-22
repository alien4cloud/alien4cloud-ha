#!/bin/bash -e

sudo cp -f $config/index.html /usr/share/nginx/html/
sudo cp -f $config/alien4cloud-logo.png /usr/share/nginx/html/
sudo cp -f $config/nginx.default /etc/nginx/sites-enabled/default

sudo sed -i -e "s/%LISTEN_PORT%/${LISTEN_PORT}/g" /etc/nginx/sites-enabled/default
sudo sed -i -e "s/%SERVICE_PORT%/${SERVICE_PORT}/g" /etc/nginx/sites-enabled/default
sudo sed -i -e "s/%SERVER_NAME%/${SERVER_NAME}/g" /etc/nginx/sites-enabled/default
