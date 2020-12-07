FROM centos:7.7.1908

RUN mv /etc/localtime /etc/localtime.bak
RUN ln -s /usr/share/zoneinfo/Europe/Istanbul /etc/localtime

RUN yum -y install git
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm http://rpms.remirepo.net/enterprise/remi-release-7.rpm

RUN yum -y install httpd; systemctl enable httpd.service
RUN rm -rf /etc/httpd/conf.d/welcome.conf

RUN yum groupinstall Development Tools -y

RUN yum install -y yum-utils
RUN yum-config-manager --enable remi-php74
RUN yum  install -y yum install php php-gettext php-devel php-pear php-gd2 php-json php-fileinfo php-openssl php-libpcre3-dev php-mcrypt php-cli php-gd php-curl php-mysqlnd php-ldap php-zip php-fileinfo php-xml php-pdo php-mbstring php-pgsql php-opcache php-simplexml

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer global require laravel/installer
RUN echo "export PATH=${HOME}/.composer/vendor/bin:${PATH}" >> /root/.bashrc
RUN composer config --global --auth --unset github-oauth.github.com

RUN yum install make ghostscript -y

RUN yum install ImageMagick ImageMagick-devel pcre-devel -y
RUN pecl install imagick 
RUN echo "extension=imagick.so" > /etc/php.d/imagick.ini

RUN yum --enablerepo=remi,remi-safe install -y phpmyadmin
RUN rm -rf /etc/httpd/conf.d/phpMyAdmin.conf
RUN rm -rf /etc/phpMyAdmin/config.inc.php

RUN curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -

RUN yum -y install php-devel pcre-devel gcc gcc-c++ make

RUN yum -y install nodejs

RUN npm install pm2 -g

RUN curl -s https://packagecloud.io/install/repositories/phalcon/stable/script.rpm.sh | bash
RUN yum -y update
RUN yum -y install php-phalcon

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

EXPOSE 80 8000