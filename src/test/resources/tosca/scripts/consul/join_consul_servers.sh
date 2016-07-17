#!/bin/bash -e

IFS=',';
CONSUL_SERVER_ADDRESSES=""
for i in $INSTANCES;
do
	varname="${i}_CONSUL_ADDRESS";
    if [ "${i}" != "${INSTANCE}" ]; then
    	CONSUL_SERVER_ADDRESSES="${!varname}"
    fi
done
echo "Joining cluster by contacting following member ${CONSUL_SERVER_ADDRESSES}"
sudo consul join ${CONSUL_SERVER_ADDRESSES}
echo "Consul has following members until now"
sudo consul members