#!/bin/bash
#nohup sudo bash -c '/var/lib/consul_template/consul-template -consul localhost:8500 -template "/etc/consul_template/nginx.conf.ctpl:/etc/nginx/sites-enabled/default:sudo /etc/init.d/nginx reload" >> /var/log/consul_template/consul_template.log 2>&1' >> /dev/null 2>&1 &
sudo /etc/init.d/nginx reload
nohup sudo bash -c '/var/lib/consul_template/consul-template -config /etc/consul_template/consul_template.conf >> /var/log/consul_template/consul_template.log 2>&1' >> /dev/null 2>&1 &
