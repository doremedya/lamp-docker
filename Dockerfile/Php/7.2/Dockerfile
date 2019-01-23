FROM centos:7.4.1708

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm http://rpms.remirepo.net/enterprise/remi-release-7.rpm

RUN yum -y install httpd; systemctl enable httpd.service
RUN rm -rf /etc/httpd/conf.d/welcome.conf

RUN yum install -y yum-utils
RUN yum-config-manager --enable remi-php72
RUN yum  install -y yum install php php-mcrypt php-cli php-gd php-curl php-mysqlnd php-ldap php-zip php-fileinfo php-xml php-pdo php-mbstring php-pgsql php-opcache php-xdebug php-simplexml

RUN yum --enablerepo=remi,remi-safe install -y phpmyadmin
RUN rm -rf /etc/httpd/conf.d/phpMyAdmin.conf
RUN rm -rf /etc/phpMyAdmin/config.inc.php

RUN curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -

RUN yum -y install gcc-c++ make

RUN yum -y install nodejs

RUN npm install pm2 -g

EXPOSE 80 8000

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]