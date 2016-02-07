#!/bin/bash

ulimit -n 32000

if [ ! -f /bundle.crt ] || [ ! -f /private.key ]; then
  MISSING_CERT=true
fi

if [ ! $MISSING_CERT ] && [ ! $TLS_GENERATE ]; then
  /opt/nginx/sbin/nginx
fi

if [ $TLS_GENERATE ]; then
  echo "Generating TLS certificate..."

  mkdir /generated-tls
  CONF_PATH=/generated-tls/config.ini
  echo "rsa-key-size = 4096" > $CONF_PATH
  echo "email = ${TLS_EMAIL:?Need to set TLS_EMAIL}" >> $CONF_PATH
  echo "domains = ${TLS_DOMAINS:?Need to set TLS_DOMAINS}" >> $CONF_PATH

  if [ $MISSING_CERT ]; then
    echo "authenticator = standalone" >> $CONF_PATH
    echo "standalone-supported-challenges = tls-sni-01" >> $CONF_PATH
  else
    echo "authenticator = webroot" >> $CONF_PATH
    echo "webroot-path = /" >> $CONF_PATH
  fi

  echo "Using following configuration file for Let's encrypt:"
  cat $CONF_PATH
  echo ""

  /letsencrypt/letsencrypt-auto certonly --agree-tos -c $CONF_PATH

  # Generate the certificates for Nginx
  IFS=',' read -ra DOMAIN <<< "$TLS_DOMAINS"
  FULLCHAIN=/etc/letsencrypt/live/$DOMAIN/fullchain.pem
  PRIVKEY=/etc/letsencrypt/live/$DOMAIN/privkey.pem
  cat $FULLCHAIN $PRIVKEY > /bundle.crt
  cat $PRIVKEY > /private.key

  /opt/nginx/sbin/nginx
fi
