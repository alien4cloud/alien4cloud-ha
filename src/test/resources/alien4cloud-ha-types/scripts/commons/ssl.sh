#!/bin/bash -e

echo "Loading ssl utils"

# Generate a key pair and keystore with certificat sign by CA.
#
# Need envs to be set :
# - $ssl: ssl dir (including ca key and certificat) location.
# - $CA_PASSPHRASE
# ARGS:
# - $1 cn
# - $2 name
# - $3 KEYSTORE_PWD
# return a temp folder containing. 
# - key.pem
# - cert.pem
# - keystore.p12
# - ca.pem
# - ca.csr	
# Should be deleted after usage.
generateKeyAndStore() {
	CN=$1
	NAME=$2
	KEYSTORE_PWD=$3
	
	TEMP_DIR=`mktemp -d`

	# echo "Generate client key"
	# Generate a key pair
	openssl genrsa -out ${TEMP_DIR}/${NAME}-key.pem 4096
	openssl req -subj "/CN=${CN}" -sha256 -new \
		-key ${TEMP_DIR}/${NAME}-key.pem \
		-out ${TEMP_DIR}/${NAME}.csr
	# Sign the key with the CA and create a certificate
	echo "[ ssl_client ]" > ${TEMP_DIR}/extfile.cnf
	echo "extendedKeyUsage=serverAuth,clientAuth" >> ${TEMP_DIR}/extfile.cnf
	openssl x509 -req -days 365 -sha256 \
	        -in ${TEMP_DIR}/${NAME}.csr -CA $ssl/ca.pem -CAkey $ssl/ca-key.pem \
	        -CAcreateserial -out ${TEMP_DIR}/${NAME}-cert.pem \
	        -passin pass:$CA_PASSPHRASE \
	        -extfile ${TEMP_DIR}/extfile.cnf -extensions ssl_client

	# poulate key store
	# echo "Generate client keystore using openssl"
	openssl pkcs12 -export -name ${NAME} \
			-in ${TEMP_DIR}/${NAME}-cert.pem -inkey ${TEMP_DIR}/${NAME}-key.pem \
			-out ${TEMP_DIR}/${NAME}-keystore.p12 -chain \
			-CAfile $ssl/ca.pem -caname root \
			-password pass:$KEYSTORE_PWD

	cp $ssl/ca.pem ${TEMP_DIR}/ca.pem
	openssl x509 -outform der -in $ssl/ca.pem -out ${TEMP_DIR}/ca.csr		

	# return the directory
	echo ${TEMP_DIR}
}