#!/usr/bin/env bash

# LAMP
debconf-set-selections <<< 'mysql-server mysql-server/root_password password rootpass'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password rootpass'
apt-get update
apt-get install -y apache2 mysql-server mysql-client php5 php5-mysql php5-gd libapache2-mod-php5 php5-curl
a2enmod rewrite

# Configure an php error log
touch /var/log/php_errors.log
chown www-data:www-data /var/log/php_errors.log
sed -i 's/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/g' /etc/php5/apache2/php.ini

# Utilities
apt-get install -y git zip unzip ruby-compass pv

# Configure git
git config --global user.name "User Name"
git config --global user.email "email@example.com"

# Get Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === 'e115a8dc7871f15d853148a7fbac7da27d6c0030b848d9b3dc09e2a0388afed865e6a3d6b3c0fad45c48e2b5fc1196ae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

# Install Composer globally
mv composer.phar /usr/local/bin/composer

# Install Drush 6.x with composer (gobally)
mkdir --parents /opt/drush-6.x
cd /opt/drush-6.x
composer init --require=drush/drush:6.* -n
composer config bin-dir /usr/local/bin
composer install

git clone "git://github.com/kraftwagen/kraftwagen.git" ~/.drush/kraftwagen

# PHPmyadmin for easy adminning
debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password rootpass'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password rootpass'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password rootpass'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2'

apt-get install -y phpmyadmin

# Varnish and Solr
apt-get install -y varnish solr-tomcat tomcat7-admin

# Create a new Tomcat-admin configuration
mv /etc/tomcat7/tomcat-users.xml /etc/tomcat7/tomcat-users.dist
sudo dd of=/etc/tomcat7/tomcat-users.xml <<EOF
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
  <!-- See tomcat-users.dist for help-->
  <role rolename="manager-gui"/>
  <user username="admin" password="rootpass" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOF

# There is no HAproxy (which is used on production), because we need no local HTTPS encryption

# Create the SPnl directory and gather the proper stuff
if ! [ -d /var/www/spnl ]; then
  mkdir /var/www/spnl

  # Git clone
  git clone https://github.com/SPWebteam/spnl.git /var/www/spnl/src
  cd /var/www/spnl

  # Kraftwagen setup: SP.nl project for development enviornment
  drush kw-s
  sed -i 's/production/development/g' cnf/environment
  chown www-data:www-data cnf/files/

  # Kraftwagen Build
  drush kw-b
fi

# Copy the solr config files
# This overrides the distribution files
cp /var/www/spnl/build/profiles/sp/modules/contrib/apachesolr/solr-conf/solr-3.x/* /usr/share/solr/conf/
service tomcat7 restart

# Create a new apache site-configuration
sudo dd of=/etc/apache2/sites-available/spnl.dev.conf <<EOF
<VirtualHost *:80>
  ServerName spnl.dev       
  ServerAdmin webmaster@localhost
  DocumentRoot /var/www/spnl/build
      ErrorLog ${APACHE_LOG_DIR}/error.log
      CustomLog ${APACHE_LOG_DIR}/access.log combined

     <Directory /var/www/spnl/build/>
       Options FollowSymlinks
       AllowOverride All
       Require all granted
     </Directory>

</VirtualHost>
EOF
a2ensite spnl.dev.conf

# PHP inline errors on
sed -i 's/display_errors = Off/display_errors = On/g' /etc/php5/apache2/php.ini

# If there is an SQL-dump in the data dir load the SQL dump

if [ -f "/vagrant/data/spnl_d7x.sql" ]
then
  # Import the desired database
  pv -i 1 -p -t -e /vagrant/data/spnl_d7x.sql | mysql -u root -prootpass
else
  #Initialize a test database
  mysql -u root -prootpass -e "CREATE DATABASE spnl_d7x";
  cd /var/www/spnl/build
  drush kw-id
fi

# Set ownership of dir
chown -R vagrant:vagrant /var/www/spnl
chmod -R 775 /var/www/spnl/cnf/files

# Varnish
cp /etc/varnish/default.vcl /etc/varnish/default-original.vcl

# Updatedb for locate
updatedb

# Create vagrant specific conf to resolve ancient bug
sudo dd of=/etc/apache2/conf-available/vagrant.conf <<EOF
# Prevent vagrant non-update bug (https://www.vagrantup.com/docs/synced-folders/virtualbox.html)
EnableSendfile Off
EOF
a2enconf vagrant.conf

# Reload
service apache2 reload
