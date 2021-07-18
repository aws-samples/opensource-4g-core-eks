#!/usr/bin/env bash

#Script to generate required SSL certs

if ls ./*.pem | grep -v rds-combined-ca-bundle.pem 2>/dev/null 1>&2; then
   echo "certificates exists..., no need to generate SSL certs"
   exit
fi

FILE=/etc/pki/CA/serial

if [[ ! -f "$FILE" ]]; then
    echo "$FILE does not exist, proceeding to create it"
    echo '1000' | sudo tee /etc/pki/CA/serial
fi

sudo touch /etc/pki/CA/index.txt

openssl req  -new -batch -x509 -days 3650 -nodes -newkey rsa:1024 -out ./cacert.pem -keyout cakey.pem -subj /CN=ca.localdomain/C=KO/ST=Seoul/L=Nowon/O=Open5GS/OU=Tests
openssl genrsa -out ./mme.key.pem 1024
openssl req -new -batch -out mme.csr.pem -key ./mme.key.pem -subj /CN=mme.localdomain/C=KO/ST=Seoul/L=Nowon/O=Open5GS/OU=Tests
sudo openssl ca -cert ./cacert.pem -days 3650 -keyfile cakey.pem -in mme.csr.pem -out ./mme.cert.pem -outdir . -batch
openssl genrsa -out ./hss.key.pem 1024
openssl req -new -batch -out hss.csr.pem -key ./hss.key.pem -subj /CN=hss.localdomain/C=KO/ST=Seoul/L=Nowon/O=Open5GS/OU=Tests
sudo openssl ca -cert ./cacert.pem -days 3650 -keyfile cakey.pem -in hss.csr.pem -out ./hss.cert.pem -outdir . -batch
openssl genrsa -out ./smf.key.pem 1024
openssl req -new -batch -out smf.csr.pem -key ./smf.key.pem -subj /CN=smf.localdomain/C=KO/ST=Seoul/L=Nowon/O=Open5GS/OU=Tests
sudo openssl ca -cert ./cacert.pem -days 3650 -keyfile cakey.pem -in smf.csr.pem -out ./smf.cert.pem -outdir . -batch
openssl genrsa -out ./pcrf.key.pem 1024
openssl req -new -batch -out pcrf.csr.pem -key ./pcrf.key.pem -subj /CN=pcrf.localdomain/C=KO/ST=Seoul/L=Nowon/O=Open5GS/OU=Tests
sudo openssl ca -cert ./cacert.pem -days 3650 -keyfile cakey.pem -in pcrf.csr.pem -out ./pcrf.cert.pem -outdir . -batch
