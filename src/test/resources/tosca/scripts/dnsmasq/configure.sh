#!/bin/bash -e

sudo /bin/su -c "echo 'no-resolv' > /etc/dnsmasq.conf"
sudo /bin/su -c "echo 'no-hosts' >> /etc/dnsmasq.conf"
sudo /bin/su -c "echo 'user=root' >> /etc/dnsmasq.conf"
#sudo /bin/su -c "echo 'cache-size=0' >> /etc/dnsmasq.conf"
sudo /bin/su -c "echo 'server=/consul/127.0.0.1#8600' >> /etc/dnsmasq.conf"
