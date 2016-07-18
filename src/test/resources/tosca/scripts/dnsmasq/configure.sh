#!/bin/bash -e


sudo cat << EOF > /etc/dnsmasq.conf
no-resolv
no-hosts
user=root
server=/consul/127.0.0.1#8600
EOF
