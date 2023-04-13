#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Process Starting for creating a virtual hosts."

read -p "What is the project path? " PROJECTPATH

if [ -z "$PROJECTPATH" ]
then
    PROJECTPATH="/var/www/html/laravel/"
else
    echo "You choose ${PROJECTPATH} project path"
fi

read -p "What is the project folder name? " PROJECTFOLDER
FULLPATH="${PROJECTPATH}${PROJECTFOLDER}"

if [ -e "$FULLPATH" ]
then
	echo -e "${RED}Sorry! The project folder is already exists in the specified path. ${NC}"
else
	if [ -z "$PROJECTFOLDER" ]
	then
		echo "You have to provide a project folder name"
	else
		echo "Your project folder name is ${PROJECTFOLDER}"
		cd $PROJECTPATH

		laravel new $PROJECTFOLDER

		sudo chown -R $USER:www-data $FULLPATH
		chmod -R 775 $FULLPATH
		cd $PROJECTFOLDER

		chmod -R 775 storage
		chmod -R 775 bootstrap/cache
	fi

	# echo "Creating a folder in ${PROJECTPATH} ...."
	# mkdir "${FULLPATH}"
	echo "A folder is created in ${PROJECTPATH}"

	#=============================================================================================================
	# Below codes are for Apache Server
	#=============================================================================================================

if [[ `ps -acx|grep apache|wc -l` > 0 ]]; then
	echo "Creating a configuration file in /etc/apache2/sites-available/"
	# /etc/apache2/sites-available/

	sudo touch "/etc/apache2/sites-available/${PROJECTFOLDER}.conf"

	if [ -e "/etc/apache2/sites-available/${PROJECTFOLDER}.conf" ]
	then
		HOSTCONFIGFILE="/etc/apache2/sites-available/${PROJECTFOLDER}.conf"
	else
		sudo touch "/etc/apache2/sites-available/${PROJECTFOLDER}.conf"
		HOSTCONFIGFILE="/etc/apache2/sites-available/${PROJECTFOLDER}.conf"
	fi

sudo sh -c "cat > $HOSTCONFIGFILE" <<EOT
<VirtualHost *:80>
	# The ServerName directive sets the request scheme, hostname and port that
	# the server uses to identify itself. This is used when creating
	# redirection URLs. In the context of virtual hosts, the ServerName
	# specifies what hostname must appear in the request's Host: header to
	# match this virtual host. For the default virtual host (this file) this
	# value is not decisive as it is used as a last resort host regardless.
	# However, you must set it for any further virtual host explicitly.
	# ServerName www.example.com

	ServerAdmin webmaster@$PROJECTFOLDER.test
	ServerName $PROJECTFOLDER.test
	ServerAlias www.$PROJECTFOLDER.test
	DocumentRoot $FULLPATH/public

	# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
	# error, crit, alert, emerg.
	# It is also possible to configure the loglevel for particular
	# modules, e.g.
	# LogLevel info ssl:warn

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with "a2disconf".
	# Include conf-available/serve-cgi-bin.conf

    ErrorLog ${FULLPATH}/error.log
	CustomLog ${FULLPATH}/access.log combined

	# For most configuration files from conf-available/, which are
	# enabled or disabled at a global level, it is possible to
	# include a line for only one particular virtual host. For example the
	# following line enables the CGI configuration for this host only
	# after it has been globally disabled with "a2disconf".
	# Include conf-available/serve-cgi-bin.conf

    <Directory $FULLPATH/public>
	Options Indexes FollowSymLinks
	AllowOverride All
	Require all granted
    </Directory>
</VirtualHost>
EOT
	# Need To Run Below Commands To Link The File into /etc/apache2/sites-enabled
	sudo a2ensite $PROJECTFOLDER.conf
	sudo systemctl reload apache2
fi


	#=============================================================================================================
	# Below codes are for Nginx Server
	#=============================================================================================================

if [ `ps -acx|grep nginx|wc -l` -gt 0 ]
then
	echo "Creating a configuration file in /etc/nginx/sites-available/"
	sudo touch "/etc/nginx/sites-available/${PROJECTFOLDER}"

	if [ -e "/etc/nginx/sites-available/${PROJECTFOLDER}" ]
	then
		HOSTCONFIGFILE="/etc/nginx/sites-available/${PROJECTFOLDER}"
	else
		sudo touch "/etc/nginx/sites-available/${PROJECTFOLDER}"
		HOSTCONFIGFILE="/etc/nginx/sites-available/${PROJECTFOLDER}"
	fi

sudo sh -c "cat > $HOSTCONFIGFILE" <<EOT
# ${PROJECTFOLDER} application server configuration
server {
	listen 80;
	listen [::]:80;

	# SSL configuration
	#
	# listen 443 ssl default_server;
	# listen [::]:443 ssl default_server;
	#
	# include snippets/snakeoil.conf;

	root /var/www/html/laravel/${PROJECTFOLDER}/public;

	# Add index.php to the list if you are using PHP
	index index.php index.html index.htm;

	server_name ${PROJECTFOLDER}.test www.${PROJECTFOLDER}.test;

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to displaying a 404.
		try_files \$uri \$uri/ /index.php?\$query_string;
	}

	# pass PHP scripts to FastCGI server
	#
	location ~ \.php$ {
		# try_files \$uri /index.php =404;
        # fastcgi_split_path_info ^(.+\.php)(/.+)$;
		# With php-fpm (or other unix sockets):
		fastcgi_pass unix:/run/php/php8.1-fpm.sock;
		fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
		# include snippets/fastcgi-php.conf;
		# With php-cgi (or other tcp sockets):
		# fastcgi_pass 127.0.0.1:9000;
	}

	# deny access to .htaccess files, if Apache's document root
	# concurs with nginx's one
	#
	location ~ /\.ht {
		deny all;
	}

	location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOT

	# Need To Run Below Commands To Link The File into /etc/apache2/sites-enabled
	sudo ln -s "/etc/nginx/sites-available/${PROJECTFOLDER}" "/etc/nginx/sites-enabled/"
	sudo systemctl reload nginx
else
	echo -e "${RED}Sorry! This shell script is working only in the Apache and Nginx Server. ${NC}"
fi
	echo -e "\n127.0.0.1 $PROJECTFOLDER.test" | sudo tee -a /etc/hosts
	echo -e "${GREEN}Everything is ready, mate! Create something awesome!${NC}"
fi
