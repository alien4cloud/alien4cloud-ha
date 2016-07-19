#!/bin/bash

sudo nohup /var/lib/consul_template/consul-template -consul localhost:8500 \
  -template "/etc/consul_template/nginx.conf.ctpl:/etc/nginx/sites-enabled/default:sudo /etc/init.d/nginx reload" >> /var/log/consul-template/consul-template/log 2>&1 &
