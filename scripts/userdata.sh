#!/bin/bash
#set -e -x
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd mariadb-server
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl is-enabled httpd
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www && sudo find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;
sudo systemctl start mariadb
sudo yum install php-mbstring -y
sudo systemctl restart httpd
sudo systemctl restart php-fpm
cd /var/www/html
sudo wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
sudo mkdir phpMyAdmin && sudo tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1
sudo rm phpMyAdmin-latest-all-languages.tar.gz
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz
sudo rm latest.tar.gz
sudo systemctl start httpd
sudo systemctl start mariadb
export DEBIAN_FRONTEND="noninteractive"
sudo mysql -u root  <<EOF
   CREATE USER 'wordpress-user'@'localhost' IDENTIFIED BY 'Stackinc1';
   CREATE DATABASE \`wordpress-db\`;
   USE \`wordpress-db\`;
   GRANT ALL PRIVILEGES ON \`wordpress-db\`.* TO 'wordpress-user'@'localhost';
   FLUSH PRIVILEGES;
EOF
sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sudo perl -pi -e 's/database_name_here/wordpress-db/g' /var/www/html/wordpress/wp-config.php
sudo perl -pi -e 's/username_here/wordpress-user/g' /var/www/html/wordpress/wp-config.php
sudo perl -pi -e 's/password_here/Stackinc1/g' /var/www/html/wordpress/wp-config.php
sudo cp -r /var/www/html/wordpress/* /var/www/html/
sudo rm -r /var/www/html/wordpress
sudo perl -i -pe 's/AllowOverride None/AllowOverride All/ if $.==151' /etc/httpd/conf/httpd.conf
sudo systemctl enable httpd && sudo systemctl enable mariadb
sudo systemctl restart mariadb
sudo systemctl restart httpd
