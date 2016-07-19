#!/bin/bash

nohup /var/lib/consul_template/consul-template -consul localhost:8500 \
  -template "/etc/consul_template/nginx.conf.ctpl:/etc/nginx/sites-enabled/default:sudo /etc/init.d/nginx reload" 2>&1 &
