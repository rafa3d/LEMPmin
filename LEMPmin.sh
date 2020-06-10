#!env bash

printf "\033[1;37m  _    ___ __  __ ___       _        _   __  
 | |  | __|  \/  | _ \_ __ (_)_ _   / | /  \ 
 | |__| _|| |\/| |  _/ '  \| | ' \  | || () |
 |____|___|_|  |_|_| |_|_|_|_|_||_| |_(_)__/ 
                                             \033[0m\n"
if [[ -e /etc/redhat-release ]]; then
    RELEASE_RPM=$(rpm -qf /etc/centos-release)
    RELEASE=$(rpm -q --qf '%{VERSION}' ${RELEASE_RPM})
    if [ ${RELEASE} != "7" ]; then
        echo "Not CentOS release 7."
        exit 1
    fi
else
    echo "Not CentOS system."
    exit 1
fi

xx=$(cat /etc/redhat-release)
printf "OS\t\tCentOS "
xxx=$(echo $xx | cut -d' ' -f 4)
printf "$xxx "
arch

ls -l /etc/localtime >&- 2>&-
timedatectl set-timezone Europe/Madrid >&- 2>&-
printf "Date\t\t"
date

printf "Port Nginx web (80)? "
read portnumber

printf "Installing ~2 minuts...\r"

start=`date +%s`

yum remove apache2 bind mysql bind9 -y >&- 2>&-
yum install -y nano wget >&- 2>&-
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa 2>/dev/null <<< y >/dev/null

cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=0
enabled=1
EOF

yum -y install nginx >&- 2>&-

xx=$(nginx -v 2>&1)
printf "Nginx version\t"
echo $xx | cut -d'/' -f 2

yum install -y epel-release yum-utils >&- 2>&-
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm >&- 2>&-
yum-config-manager --enable remi-php73 >&- 2>&-

yum install -y php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysqlnd >&- 2>&-

yum install -y php-fpm >&- 2>&-

systemctl enable php-fpm >&- 2>&-
systemctl start php-fpm >&- 2>&-

xx=$(php -v 2>&1)
printf "PHP version\t"
echo $xx | cut -d' ' -f 2

yum install -y mariadb-server >&- 2>&-
systemctl enable mariadb >&- 2>&-
systemctl start mariadb >&- 2>&-

pass=$(openssl rand -base64 8 2>&1)
echo -e "\n\n$pass\n$pass\n\n\n\n\n" | mysql_secure_installation >&- 2>&-
#>/dev/null

xx=$(yum info mariadb)
xxx=$(echo $xx | cut -d':' -f 12)
printf "MariaDB installed version"
printf "$xxx"
printf "with pass: $pass\n"

mkdir -p /usr/local/nginx/html >&- 2>&-
cd /usr/local/nginx/html/ >&- 2>&-
wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.xz >/dev/null 2>&1
mkdir dbgui >&- 2>&-
tar -xf phpMyAdmin-latest-english.tar.xz -C dbgui --strip=1 >&- 2>&-
rm -rf phpMyAdmin-latest-english.tar.xz >&- 2>&-

printf "phpMyAdmin installed \t/usr/local/nginx/html/dbgui\r"


printf "Modifing Nginx and PHP-fpm files\r"
echo 'server {
    listen       80;
    server_name  localhost;
    location / {
        root    /usr/local/nginx/html;
        index  index.html index.htm index.php;
    }
    location ~ \.php$ {
        root           html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param SCRIPT_FILENAME /usr/local/nginx/html$fastcgi_script_name;
        include        fastcgi_params;
    }
}' > /etc/nginx/conf.d/default.conf

printf "Creating index.php with phpinfo()\n"
touch /usr/local/nginx/html/index.php >&- 2>&-
echo '<?php phpinfo();' > /usr/local/nginx/html/index.php

if [ -z "$portnumber" ]
then
    portnumber=80
fi


sed -i "s/80;/$portnumber;/g" /etc/nginx/conf.d/default.conf
sed -i "s/www-error.log/www-php.error.log/g" /etc/php-fpm.d/www.conf

service php-fpm restart >&- 2>&-
service nginx restart >&- 2>&-


printf "Nginx conf\t\033[1;34m/etc/nginx/conf.d/default.conf\033[0m\n"
printf "PHP-FPM conf\t\033[1;34m/etc/php-fpm.d/www.conf\033[0m\n"
printf "Web index\t\033[1;34m/usr/local/nginx/html/index.php\033[0m\n"

end=`date +%s`

yum clean all >/dev/null 2>&1

runtime=$((end-start))

printf "Execution time\t\033[1;37m${runtime} seconds\033[0m\n"

printf "phpMyAdmin URL\t\033[1;32mhttp://148.251.3.246:${portnumber}/dbgui/\033[0m\n"
printf "Nginx web URL\t\033[1;32mhttp://148.251.3.246:${portnumber}/\033[0m\n"

