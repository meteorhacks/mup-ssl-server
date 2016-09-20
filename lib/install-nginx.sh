set -e

BUILD_DIR=/tmp/nginx
NGINX_VERSION=1.8.0
PREFIX=/opt/nginx
NGINX_USER=nginx

# creating a non-privileged user
useradd $NGINX_USER || :

# install dependencies
apt-get update
apt-get -y install libpcre3-dev libssl-dev openssl build-essential wget
apt-get -y --only-upgrade install libssl1.0.0 openssl

# start building process

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
mkdir -p $PREFIX
cd $BUILD_DIR

# download nginx
wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar xvzf nginx-$NGINX_VERSION.tar.gz

# building
cd nginx-$NGINX_VERSION
./configure \
  --prefix=$PREFIX --user=$NGINX_USER --group=$NGINX_USER \
  --with-http_ssl_module --without-http_scgi_module \
  --without-http_uwsgi_module --without-http_fastcgi_module

make install

# remove build specific libraries
apt-get -y remove build-essential wget
apt-get -y autoremove

# generate new Diffie-Hellman group
openssl dhparam -out /dhparams.pem 2048
