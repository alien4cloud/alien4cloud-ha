#!/bin/bash
echo "=========================== starting nginx ==========================="
#sudo /bin/su -c "echo 'nameserver 127.0.0.1' > /etc/resolv.conf"
#echo "sleeping 30s just to ensure A4C will be up"
#sleep 30
sudo /etc/init.d/nginx status
sudo /etc/init.d/nginx start
sudo /etc/init.d/nginx reload
