#!/bin/bash

stop_service()
{
# ps aux | grep "lxdm.*-d" | grep -v grep | awk {'print $2'} | while read i ; do kill -9 ${i}; done
for sys_service in nginx mysql php5-fpm; do service ${sys_service} stop; done
}

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
/install.sh
}
mysql_start()
{
times=0
service mysql stop
rm -f /var/run/mysqld/mysqld.pid
pidof mysqld && killall mysqld
while true;do service mysql start;sleep 3;time=$(expr $times + 1); [ $times -ge 10 ] && break ;ps aux |grep mysqld ;pidof mysqld && break;done
}

if 
[ -d /work/ ]
then
sed -i 's#datadir.*#datadir = /work/mysql#' /etc/mysql/my.cnf
fi

username=$(ls /home/ | sed -n 1p)
if
[ -n "$username" ]
then
USER_NAME="$username"
which mysqld && mysql_start
else
initialize
cat <<EOF
username: $USER_NAME
password: $USER_PASSWORD
Initialize Finished.Have Fun.
EOF
my_id=$$
ps aux | grep -vE "grep|^USER.*PID" | awk '{print $2}' | grep -v "^$my_id$" | while read pid
do
kill -9 ${pid} 2>/dev/null
done
exit 0
fi

if 
[ -d /work/ ] && [ ! -d /work/mysql ]
then
mkdir -p /work/mysql
cp -R /var/lib/mysql/* /work/mysql/
chown -R mysql /work/mysql/
mysql_start
fi


# su $USER_NAME <<EOF
# EOF

# test
# useradd --create-home --shell /bin/bash --user-group --groups adm,sudo,www-data notroot
# passwd notroot <<EOF >/dev/null 2>&1
# notroot
# notroot
# EOF
# test

mkdir -p /var/run/sshd
exec /usr/sbin/sshd -D

