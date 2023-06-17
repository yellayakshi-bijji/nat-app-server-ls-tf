#! /bin/bash

set -e #Immediate exit if any command fails

NAT_SERVER_IP=${aws_instance.natinstance.public_ip}

echo "http_proxy=http://${NAT_SERVER_IP}:3128" >> /etc/environment
echo "https_proxy=http://${NAT_SERVER_IP}:3128" >> /etc/environment
echo "ftp_proxy=http://${NAT_SERVER_IP}:3128" >> /etc/environment
echo "no_proxy=169.254.169.254" >> /etc/environment

echo "Updating packages..."
sudo yum update -y

echo "Installing packages.."
sudo yum install -y httpd
echo "Installed httpd"

sudo yum install -y wget
echo "Installed wget"

sudo yum install -y php
echo "Installed php"

sudo yum install -y php-mysqli
echo "Installed php-mysqli"

sudo yum install -y php-devel
echo "Installed php-devel"

sudo yum install -y mariadb105-server
echo "Installed mariadb105-server"

echo "Starting httpd service..."
sudo systemctl start httpd
sudo systemctl enable httpd

echo "Adding user to Apache group..."
sudo usermod -a -G apache ec2-user

echo "Setting ownership and permissions..."
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www && find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

echo "Creating phpinfo.php..."
echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php

echo "Downloading and setting up phpMyAdmin..."
cd /var/www/html
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
mkdir phpMyAdmin && tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1
rm phpMyAdmin-latest-all-languages.tar.gz

echo "Starting MariaDB service..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

echo "Securing MariaDB installation..."
sudo mysql_secure_installation <<EOFSCRIPT
   Y
   testtrial@123
   testtrial@123
   Y
   Y
   Y
   Y
EOFSCRIPT
echo "Cloud-init log:"
cat /var/log/cloud-init-output.log
# Save the contents of the log file to a local file
cat /var/log/cloud-init-output.log > ~/cloud-init-log.txt
echo "User data script execution completed."