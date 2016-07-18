#!/bin/bash -e
echo "=========================== starting nginx ==========================="
sudo cat << EOF > /etc/resolv.conf
nameserver 127.0.0.1
EOF
sudo /etc/init.d/nginx status
sudo /etc/init.d/nginx start
sudo /etc/init.d/nginx status
