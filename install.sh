#!/bin/sh
# Write by EK. Which from Amoy FJ CN.
if
[ `grep "^$(whoami):" /etc/passwd | cut -d: -f4` -ne 0 ]
then
echo "You must Run this script as root!!!"
exit 1
fi

initialize()
{
if
[ -n "$USER_NAME" ]
then
result=0 && for name in $(cat /etc/passwd | cut -d ":" -f1)
do
[ "$USER_NAME" = "${name}" ] && result=$(expr $result + 1) && break
done
[ $result -ne 0 ] && USER_NAME=notroot
else
USER_NAME=notroot
fi
[ -n "$USER_PASSWORD" ] || USER_PASSWORD="notroot"

useradd --create-home --shell /bin/bash --user-group --groups adm,sudo,www-data $USER_NAME

passwd $USER_NAME <<EOF >/dev/null 2>&1
$USER_PASSWORD
$USER_PASSWORD
EOF
}
username=$(ls /home/ | sed -n 1p)
if
[ -n "$username" ]
then
USER_NAME="$username"
else
initialize
fi

useradd $USER_NAME -m -G sudo,www-data,adm -s /bin/bash
# su -l $USER_NAME <<'CMD'
# touch ~/.flarumrc
# CMD

base_setting()
{
##### System Base setting
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
locale-gen C.UTF-8

export LANG=C.UTF-8
grep -q "export LANG=C.UTF-8" ~/.bashrc || echo "export LANG=C.UTF-8" >> /root/.bashrc

apt-get update -y
apt-get install -y wget # software-properties-common python-software-properties curl unzip 
##### System Base setting
}

mysql_ins()
{
# MySQL Installtion
echo ">>> Installing MySQL Server"

mysql_root_password=root
# mysql_version=5.7
mysql_enable_remote="true"

# mysql_package=mysql-server
mysql_package=mysql-server-5.7


# wget http://dev.mysql.com/get/mysql-apt-config_0.3.2-1ubuntu14.04_all.deb -O /tmp/mysql.deb

# echo "mysql-apt-config mysql-apt-config/enable-repo select mysql-5.7-dmr" | debconf-set-selections
# dpkg -i /tmp/mysql.deb

# if [ "$mysql_version" = "5.7" ]; then
#     # Add repo for MySQL 5.7
# 	add-apt-repository -y ppa:ondrej/mysql-5.7

# 	# Update Again
# 	apt-get update

# 	# Change package
# 	mysql_package=mysql-server-5.7
# fi

# Install MySQL without password prompt
apt-get purge -y mysql*
apt-get autoremove -y
apt-get autoclean -y
rm -rf /var/lib/mysql
rm -rf /var/log/mysql


apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5

cat <<EOL  > /etc/apt/sources.list.d/mysql.list
# You may comment out entries below, but any other modifications may be lost.
# Use command 'dpkg-reconfigure mysql-apt-config' as root for modifications.
deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-apt-config
deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7-dmr
# deb http://repo.mysql.com/apt/ubuntu/ trusty workbench-6.3
# deb http://repo.mysql.com/apt/ubuntu/ trusty connector-python-2.0
# deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-utilities-1.5
EOL

apt-get update -y
export DEBIAN_FRONTEND="noninteractive"

echo "mysql-community-server mysql-community-server/root-pass password $mysql_root_password" | debconf-set-selections
echo "mysql-community-server  mysql-community-server/re-root-pass password $mysql_root_password" | debconf-set-selections

apt-get install -y mysql-server



# Set username and password to 'root'


# sudo apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" mysql-server


# Make MySQL connectable from outside world without SSH tunnel
if [ "$mysql_enable_remote" = "true" ]; then
    # enable remote access
    # setting the mysql bind-address to allow connections from everywhere
    sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

    # adding grant privileges to mysql root user from everywhere
    # thx to http://stackoverflow.com/questions/7528967/how-to-grant-mysql-privileges-in-a-bash-script for this
    MYSQL=`which mysql`

    Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$1' WITH GRANT OPTION;"
    Q2="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}"

    $MYSQL -uroot -p$1 -e "$SQL"

    # service mysql restart
    service mysql stop
	mysql_start
fi
##### MySQL Installtion
}
mysql_start()
{
times=0
while true;do service mysql start;sleep 3;time=$(expr $times + 1); [ $times -ge 10 ] && break ;ps aux |grep mysqld ;pidof mysqld && break;done
}

base_setting
mysql_ins
