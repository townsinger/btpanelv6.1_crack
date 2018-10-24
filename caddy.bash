#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function update(){

apt-get update -y
apt-get install -y gcc g++ make zip lrzsz psmisc autoconf curl libxml2 libxml2-dev libssl-dev bzip2 libbz2-dev libjpeg-dev  libpng12-dev libfreetype6-dev libgmp-dev libmcrypt-dev libreadline6-dev libsnmp-dev libxslt1-dev libcurl4-openssl-dev pkg-config libssl-dev libsslcommon2-dev libzip-dev
#yum install gcc g++ make zip lrzsz autoconf curl libcurl libcurl-devel psmisc libpng-devel libzip cmake libzip-devel libxml2 libxml2-devel freetype-devel bzip2 libjpeg-devel libpng12-devel libmcrypt-devel openssl-devel
groupadd -r php
groupadd -r www
useradd -r -g php -s /bin/false -d /usr/local/php -M php
useradd -r -g www -s /bin/false -d /usr/local/www -M www

}



function install-php(){
mkdir php
cd php
wget http://am1.php.net/distributions/php-7.2.10.tar.gz
tar -zxf php-7.2.10.tar.gz
cd php-7.2.10
#wget https://downloads.php.net/~cmb/php-7.3.0beta3.tar.gz
#tar -zxf php-7.3.0beta3.tar.gz
#cd php-7.3.0beta3
ossl=`find / -name libssl.so`
ln -s $ossl /usr/lib
./configure --prefix=/usr/local/php --exec-prefix=/usr/local/php --bindir=/usr/local/php/bin --sbindir=/usr/local/php/sbin --includedir=/usr/local/php/include --libdir=/usr/local/php/lib/php --mandir=/usr/local/php/php/man --with-config-file-path=/usr/local/php/etc --with-mysql-sock=/var/run/mysql/mysql.sock --with-mhash --with-openssl --with-mysqli=shared,mysqlnd --with-pdo-mysql=shared,mysqlnd --with-gd --with-iconv --with-zlib --enable-zip --enable-inline-optimization --disable-debug --disable-rpath --enable-shared --enable-xml --enable-bcmath --enable-shmop --enable-sysvsem --enable-mbregex --enable-mbstring --enable-ftp --enable-pcntl --enable-sockets --with-xmlrpc --enable-soap --without-pear --with-gettext --enable-session --with-curl --with-jpeg-dir --with-freetype-dir --enable-opcache --enable-fpm --with-fpm-user=php --with-fpm-group=php --without-gdbm --disable-fileinfo
make && make install
echo "
export PHP_HOME=/usr/local/php
export PATH=\$PHP_HOME/bin:\$PATH
" >> /etc/profile
source /etc/profile
cp sapi/fpm/init.d.php-fpm /usr/local/bin/php-fpm
chmod +x /usr/local/bin/php-fpm
cp php.ini-production /usr/local/php/etc/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf

echo "
; Start a new pool named 'www'
[www]
listen = /usr/local/php/var/run/\$pool-php-fpm.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0660
user = www
group = www
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
pm.status_path = /status
ping.path = /ping
ping.response = pong
request_terminate_timeout = 100
request_slowlog_timeout = 10s
slowlog = /usr/local/php/var/log/$pool.log.slow
" >> /usr/local/php/etc/php-fpm.d/www.conf

/usr/local/bin/php-fpm start

}


function install-caddy(){
curl https://getcaddy.com | bash -s personal http.cgi,http.filemanager
mkdir -p /data/www
echo "import conf.d/*" > /etc/caddy/caddy.conf
mkdir -p /etc/ssl/caddy
mkdir -p /etc/caddy
chown -R www:www /etc/ssl/caddy
chown -R www:www /data/www/
chmod 0770 /etc/ssl/caddy
IP=`curl http://whatismyip.akamai.com`
wget -O /data/www/default/index.html "https://img.ppxwo.com/html/index.html"
echo "
http://$IP {
root /data/www/default
gzip
fastcgi / /usr/local/php/var/run/www-php-fpm.sock {
  ext     .php
  split   .php
  index   index.php
}
}
" >> /etc/caddy.conf
#transparent
#/run/php/php7.0-fpm.sock
ulimit -n 51200
nohup caddy -conf=/etc/caddy.conf -agree >> /tmp/caddy.log 2>&1 & 

wget -O /usr/bin/http "https://img.ppxwo.com/shell/http"
chmod +x /usr/bin/http
echo "管理脚本使用方法： "
http
}

update
install-php
install-caddy

ifconfig eth0 | grep bytes |  awk -F"(" '{print $2}' |awk -F")" '{print $1}' | awk 'NR==1{print}' #出流量
ifconfig eth0 | grep bytes |  awk -F"(" '{print $2}' |awk -F")" '{print $1}' | awk 'NR==2{print}' #进流量



#Centos
#wget https://libzip.org/download/libzip-1.5.1.tar.gz
#tar -zxf libzip-1.5.1.tar.gz
#cd libzip-1.5.1
#wget https://cmake.org/files/v3.12/cmake-3.12.3.tar.gz
#tar -xzf cmake-3.12.3.tar.gz
#cd cmake-3.12.3
#./bootstrap && make && make install
#ln -s /usr/local/bin/cmake /usr/local/bin/cmake
#cd ../ && cd ../ && cmake .. && make && make install
#echo '/usr/local/libzip/lib' >> /etc/ld.so.conf.d/custom-libs.conf
#echo "/usr/local/lib
#/usr/local/lib64
#/usr/lib
#/usr/lib64
#" >>/etc/ld.so.conf.d/local.conf
#ldconfig -v
#ln -vs /usr/local/libzip/include/zipconf.h /usr/local/include
#cd ../ && cd ../ && make && make install 
#