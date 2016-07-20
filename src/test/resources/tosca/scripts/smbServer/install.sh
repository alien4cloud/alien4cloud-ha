#!/bin/bash -e
LOCK="/tmp/lockaptget"

while true; do
	if mkdir "${LOCK}" &>/dev/null; then
		echo "take apt lock"
    	break;
	fi
	echo "waiting apt lock to be released..."
    sleep 2
done

while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    echo "$NAME waiting for other software managers to finish..."
    sleep 2
done

sudo apt-get -y update >/dev/null 2>&1
sudo apt-get -y install samba >/dev/null 2>&1

rm -rf "${LOCK}"
echo "released apt lock"

sudo service smbd stop
sudo service nmbd stop
