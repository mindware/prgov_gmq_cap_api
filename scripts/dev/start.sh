USER_HOME=$(eval echo ~${SUDO_USER})
$USER_HOME/gmq/twemproxy/src/nutcracker -c $USER_HOME/gmq/twemproxy/conf/gmq.yml &
redis-server /usr/local/etc/redis.conf & 
redis-server /usr/local/etc/redis2.conf &
