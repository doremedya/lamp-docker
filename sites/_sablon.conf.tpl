# __AD__ (~/projeler/__KLASOR__)
<VirtualHost *:80>
    ServerName __AD__.test
    ServerAlias www.__AD__.test test.__AD__.test

    DocumentRoot /var/www/html/__KLASOR__

    <Directory /var/www/html/__KLASOR__>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/__AD___error.log
    CustomLog ${APACHE_LOG_DIR}/__AD___access.log combined
</VirtualHost>
