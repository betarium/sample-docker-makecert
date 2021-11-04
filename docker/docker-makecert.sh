#!/bin/sh

USAGE=`cat << EOM
    Usage:
      <CA_NAME> <ACTION> <CERT_NAME> [option...]

      Create CA Cert.           <CA_NAME> ca
      Create server cert.       <CA_NAME> server <CERT_NAME> [COMMON_NAME]
      Show cert file.           <CA_NAME> show [CERT_NAME]

    example:
      example_com_ca ca
      example_com_ca server example.com *.example.com
      example_com_ca show example.com
EOM
`

########################################

if [ "$1" = "--build" ]; then
  shift
fi

if [ $# -eq 0 -o "$1" = "help" -o "$1" = "--help" -o "$1" = "" ]; then

  IFS='' && echo "$USAGE"

  exit 0
fi

if [ "$1" = "bash" ]; then

  bash

  exit 0

fi

########################################

CA_NAME=$1
ACTION=$2
CERT_NAME=$1

CA_DIR=$CA_NAME
CONF_DIR=$CA_DIR/conf

########################################

if [ ! -d $CA_DIR -a ! $CA_DIR = "." ]; then
  mkdir $CA_DIR
fi

if [ ! -d $CONF_DIR ]; then
  mkdir $CONF_DIR
  echo "01" > $CONF_DIR/serial
  echo "00" > $CONF_DIR/crlnumber
  touch $CONF_DIR/index.txt

  cp /etc/ssl/openssl.cnf $CONF_DIR/

  echo "[ CA_default ]" >> $CONF_DIR/openssl.cnf
  echo "dir             = $CA_DIR" >> $CONF_DIR/openssl.cnf
  echo "database        = $CONF_DIR/index.txt" >> $CONF_DIR/openssl.cnf
  echo "serial          = $CONF_DIR/serial" >> $CONF_DIR/openssl.cnf
  echo "crlnumber       = $CONF_DIR/crlnumber" >> $CONF_DIR/openssl.cnf

  chmod -R 777 $CA_DIR
fi

if [ "$ACTION" = "ca" ]; then

  if [ -f $CA_DIR/$CERT_NAME.crt ]; then
    echo "error: cert file already exists."
    exit 2
  fi

  COMMON_NAME=$CA_NAME
  SUBJECT="/C=JP/ST=Tokyo/O=$CERT_NAME/CN=$COMMON_NAME"

  openssl genrsa 2048 > $CA_DIR/$CERT_NAME.key

  openssl req -new -subj $SUBJECT -key $CA_DIR/$CERT_NAME.key -out $CONF_DIR/$CERT_NAME.csr.tmp

  openssl ca -selfsign -batch -keyfile $CA_DIR/$CERT_NAME.key -extensions v3_ca -config $CONF_DIR/openssl.cnf -in $CONF_DIR/$CERT_NAME.csr.tmp -out $CA_DIR/$CERT_NAME.crt -days 365 -outdir $CONF_DIR

  openssl x509 -in $CA_DIR/$CERT_NAME.crt -inform PEM -out $CA_DIR/$CERT_NAME.der -outform der
  openssl x509 -in $CA_DIR/$CERT_NAME.der -inform DER -out $CA_DIR/$CERT_NAME.pem -outform pem
  openssl pkcs12 -export -passout pass: -in $CA_DIR/$CERT_NAME.pem -inkey $CA_DIR/$CERT_NAME.key -out $CA_DIR/$CERT_NAME.pfx

  chmod -R 777 $CA_DIR

elif [ "$ACTION" = "server" ]; then
  if [ "$3" = "" ]; then
    echo "error: invalid parameter. CERT_NAME required."
    exit 1
  fi

  CERT_NAME=$3
  COMMON_NAME=${4:-$CERT_NAME}
  SUBJECT="/C=JP/ST=Tokyo/O=$CERT_NAME/CN=$COMMON_NAME"

  if [ -f $CA_DIR/$CERT_NAME.crt ]; then
    echo "error: cert file already exists."
    exit 2
  fi

  openssl genrsa 2048 > $CA_DIR/$CERT_NAME.key

echo "
basicConstraints = critical, CA:false
keyUsage = critical, cRLSign, keyCertSign, keyEncipherment, digitalSignature, dataEncipherment
extendedKeyUsage = serverAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
subjectAltName = DNS:$COMMON_NAME
" >> $CONF_DIR/$CERT_NAME.ext.cnf

  openssl req -new -subj $SUBJECT -key $CA_DIR/$CERT_NAME.key -out $CONF_DIR/$CERT_NAME.csr.tmp

  openssl x509 -req -in $CONF_DIR/$CERT_NAME.csr.tmp -CA $CA_DIR/$CA_NAME.crt -CAkey $CA_DIR/$CA_NAME.key -days 365 -extfile $CONF_DIR/$CERT_NAME.ext.cnf -CAserial $CONF_DIR/serial -out $CA_DIR/$CERT_NAME.crt

  openssl x509 -in $CA_DIR/$CERT_NAME.crt -inform PEM -out $CA_DIR/$CERT_NAME.der -outform der
  openssl x509 -in $CA_DIR/$CERT_NAME.der -inform DER -out $CA_DIR/$CERT_NAME.pem -outform pem
  openssl pkcs12 -export -passout pass: -in $CA_DIR/$CERT_NAME.pem -inkey $CA_DIR/$CERT_NAME.key -out $CA_DIR/$CERT_NAME.pfx

  chmod -R 777 $CA_DIR

elif [ "$ACTION" = "show" ]; then
  CERT_NAME=${3:-$CA_NAME}

  openssl x509 -noout -text -in $CA_DIR/$CERT_NAME.crt 

else
  echo "error: invalid action. action ""$ACTION"" not support."
  IFS='' && echo "$USAGE"
  exit 1
fi

