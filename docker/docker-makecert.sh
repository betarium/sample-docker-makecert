#!/bin/bash

VERSION="1.0.1"

USAGE=`cat << EOM
    Usage:
      makecert <ACTION> <option...>

      Create CA certificate.            ca <CA_NAME>
      Create server certificate.        server <CA_NAME> <CERT_NAME> [COMMON_NAME]
      Create self sigin certificate.    self <CA_NAME> <CERT_NAME> [COMMON_NAME]
      Show certificate file.            show <CA_NAME> [CERT_NAME]

    Example:
      makecert ca example_com_ca
      makecert server example_com_ca example.com.local *.example.com.local
      makecert show example_com_ca example.com.local
EOM
`

########################################

if [ "$1" = "--build" ]; then
  shift
fi

if [ $# -eq 0 -o "$1" = "help" -o "$1" = "--help" -o "$1" = "" ]; then

  echo ""
  echo "makecert ver $VERSION"
  openssl version
  echo ""

  IFS='' && echo "$USAGE"

  exit 0
fi

if [ "$1" = "bash" ]; then

  bash

  exit 0

fi

########################################

ACTION=$1
CA_NAME=$2
CERT_NAME=${3:-$CA_NAME}
COMMON_NAME=${4:-$CERT_NAME}

CA_DIR=cert/$CA_NAME
CONF_DIR=$CA_DIR/conf

########################################

COMMON_NAME_ARRAY=${COMMON_NAME//,/ }
COMMON_NAME=(${COMMON_NAME_ARRAY})

tmp=""
for line in $COMMON_NAME_ARRAY
do
  if [ "$tmp" != "" ] ; then
    tmp="$tmp, "
  fi
  tmp="$tmp""DNS:$line"
done

SUBJECT_ALT_NAMES=$tmp

########################################

if [ "$ACTION" = "ca" -o "$ACTION" = "self" ] && [ ! -d $CONF_DIR ]; then

  if [ ! -d $CA_DIR -a ! $CA_DIR = "." ]; then
    mkdir $CA_DIR
    chmod -R 777 $CA_DIR
  fi

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

if [ "$ACTION" = "self" ]; then

  if [ -f $CA_DIR/$CERT_NAME.crt ]; then
    echo "error: cert file already exists."
    exit 2
  fi

  SUBJECT="/C=JP/ST=Tokyo/O=$CERT_NAME/CN=$COMMON_NAME"

  openssl genrsa 2048 > $CA_DIR/$CERT_NAME.key

echo "
basicConstraints = critical,CA:true
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
keyUsage = critical, cRLSign, keyCertSign, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = $SUBJECT_ALT_NAMES
" > $CONF_DIR/$CERT_NAME.ext.cnf

  openssl req -new -subj $SUBJECT -key $CA_DIR/$CERT_NAME.key -out $CONF_DIR/$CERT_NAME.csr.tmp

  openssl ca -selfsign -batch -keyfile $CA_DIR/$CERT_NAME.key -config $CONF_DIR/openssl.cnf -in $CONF_DIR/$CERT_NAME.csr.tmp -out $CA_DIR/$CERT_NAME.crt -days 365 -extfile $CONF_DIR/$CERT_NAME.ext.cnf -outdir $CONF_DIR

  openssl x509 -in $CA_DIR/$CERT_NAME.crt -inform PEM -out $CA_DIR/$CERT_NAME.pem -outform pem
  openssl x509 -in $CA_DIR/$CERT_NAME.crt -inform PEM -out $CA_DIR/$CERT_NAME.der -outform der
  openssl pkcs12 -export -passout pass: -in $CA_DIR/$CERT_NAME.pem -inkey $CA_DIR/$CERT_NAME.key -out $CA_DIR/$CERT_NAME.pfx

  chmod -R 777 $CA_DIR

  echo "Create self signed certificate. File=$CA_DIR/$CERT_NAME.crt"

elif [ "$ACTION" = "ca" ]; then

  if [ -f $CA_DIR/$CERT_NAME.crt ]; then
    echo "error: cert file already exists."
    exit 2
  fi

  SUBJECT="/C=JP/ST=Tokyo/O=$CERT_NAME/CN=$COMMON_NAME"

  openssl genrsa 2048 > $CA_DIR/$CERT_NAME.key

echo "
basicConstraints = critical,CA:true
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
keyUsage = critical, cRLSign, keyCertSign
" > $CONF_DIR/$CERT_NAME.ext.cnf

  openssl req -new -subj $SUBJECT -key $CA_DIR/$CERT_NAME.key -out $CONF_DIR/$CERT_NAME.csr.tmp

  openssl ca -selfsign -batch -keyfile $CA_DIR/$CERT_NAME.key -config $CONF_DIR/openssl.cnf -in $CONF_DIR/$CERT_NAME.csr.tmp -out $CA_DIR/$CERT_NAME.crt -days 3650 -extfile $CONF_DIR/$CERT_NAME.ext.cnf -outdir $CONF_DIR

  openssl x509 -in $CA_DIR/$CERT_NAME.crt -inform PEM -out $CA_DIR/$CERT_NAME.pem -outform pem
  openssl x509 -in $CA_DIR/$CERT_NAME.crt -inform PEM -out $CA_DIR/$CERT_NAME.der -outform der
  openssl pkcs12 -export -passout pass: -in $CA_DIR/$CERT_NAME.pem -inkey $CA_DIR/$CERT_NAME.key -out $CA_DIR/$CERT_NAME.pfx

  chmod -R 777 $CA_DIR/$CERT_NAME.*

  echo "Create CA certificate. File=$CA_DIR/$CERT_NAME.crt"

elif [ "$ACTION" = "server" ]; then
  if [ "$3" = "" ]; then
    echo "error: invalid parameter. CERT_NAME required."
    exit 1
  fi

  SUBJECT="/C=JP/ST=Tokyo/O=$CERT_NAME/CN=$COMMON_NAME"

  if [ -f $CA_DIR/$CERT_NAME.crt ]; then
    echo "error: cert file already exists."
    exit 2
  fi

  openssl genrsa 2048 > $CA_DIR/$CERT_NAME.key

echo "
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = serverAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
subjectAltName = $SUBJECT_ALT_NAMES
" > $CONF_DIR/$CERT_NAME.ext.cnf

  openssl req -new -subj $SUBJECT -key $CA_DIR/$CERT_NAME.key -out $CONF_DIR/$CERT_NAME.csr.tmp

  openssl x509 -req -text -in $CONF_DIR/$CERT_NAME.csr.tmp -CA $CA_DIR/$CA_NAME.crt -CAkey $CA_DIR/$CA_NAME.key -days 365 -extfile $CONF_DIR/$CERT_NAME.ext.cnf -CAserial $CONF_DIR/serial -out $CA_DIR/$CERT_NAME.crt

  cat $CA_DIR/$CERT_NAME.crt $CA_DIR/$CA_NAME.crt > $CA_DIR/$CERT_NAME.chain.crt

  openssl x509 -in $CA_DIR/$CERT_NAME.crt -inform PEM -out $CA_DIR/$CERT_NAME.pem -outform pem
  openssl x509 -in $CA_DIR/$CERT_NAME.crt -inform PEM -out $CA_DIR/$CERT_NAME.der -outform der
  openssl pkcs12 -export -passout pass: -in $CA_DIR/$CERT_NAME.pem -inkey $CA_DIR/$CERT_NAME.key -out $CA_DIR/$CERT_NAME.pfx

  chmod -R 777 $CA_DIR/$CERT_NAME.*

  echo "Create server certificate. File=$CA_DIR/$CERT_NAME.crt"

elif [ "$ACTION" = "show" ]; then
  CERT_NAME=${3:-$CA_NAME}

  openssl x509 -noout -text -in $CA_DIR/$CERT_NAME.crt 

else
  echo "error: invalid action. action ""$ACTION"" not support."
  IFS='' && echo "$USAGE"
  exit 1
fi

