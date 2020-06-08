#!env bash

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


ls -l /etc/localtime
timedatectl set-timezone Europe/Madrid

yum remove -y apache2 httpd bind mysql bind9
yum install -y nano wget sudo
ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa 2>/dev/null <<< y >/dev/null


cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/\$basearch/
gpgcheck=0
enabled=1
EOF

yum -y install nginx

yum install -y epel-release yum-utils
yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php73
 
yum install -y php php-common php-opcache php-mcrypt php-cli php-gd php-curl 
#quito php-mysqlnd

yum install -y php-fpm

systemctl enable php-fpm
systemctl start php-fpm


echo 'server {
    listen       16149;
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

sed -i 's/80;/16149;/g' /etc/nginx/conf.d/default.conf
sed -i 's/www-error.log/www-php.error.log/g' /etc/php-fpm.d/www.conf

service php-fpm restart
service nginx restart
