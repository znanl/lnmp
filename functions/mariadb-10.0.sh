#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# Blog:  http://blog.linuxeye.com

Install_MariaDB-10-0()
{
cd $lnmp_dir/src
. ../functions/download.sh 
. ../functions/check_os.sh
. ../options.conf

public_IP=`../functions/get_public_ip.py`
if [ "`../functions/get_ip_area.py $public_IP`" == '\u4e2d\u56fd' ];then
	FLAG_IP=CN
fi

echo $public_IP $FLAG_IP

[ "$FLAG_IP"x == "CN"x ] && DOWN_ADDR=http://mirrors.aliyun.com/mariadb || DOWN_ADDR=https://downloads.mariadb.org/f
[ -d "/lib64" ] && { SYS_BIT_a=x86_64;SYS_BIT_b=x86_64; } || { SYS_BIT_a=x86;SYS_BIT_b=i686; }
LIBC_VERSION=`getconf -a | grep GNU_LIBC_VERSION | awk '{print $NF}'`
LIBC_YN=`echo "$LIBC_VERSION < 2.14" | bc`
[ $LIBC_YN == '1' ] && GLIBC_FLAG=linux || GLIBC_FLAG=linux-glibc_214 

src_url=$DOWN_ADDR/mariadb-10.0.18/bintar-${GLIBC_FLAG}-$SYS_BIT_a/mariadb-10.0.18-${GLIBC_FLAG}-${SYS_BIT_b}.tar.gz && Download_src

useradd -M -s /sbin/nologin mysql
mkdir -p $mariadb_data_dir;chown mysql.mysql -R $mariadb_data_dir
tar zxf mariadb-10.0.18-${GLIBC_FLAG}-${SYS_BIT_b}.tar.gz 
mv mariadb-10.0.18-linux-${SYS_BIT_b} $mariadb_install_dir 
if [ "$je_tc_malloc" == '1' ];then
	sed -i 's@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=/usr/local/lib/libjemalloc.so@' $mariadb_install_dir/bin/mysqld_safe
elif [ "$je_tc_malloc" == '2' ];then
	sed -i 's@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=/usr/local/lib/libtcmalloc.so@' $mariadb_install_dir/bin/mysqld_safe
fi

if [ -d "$mariadb_install_dir" ];then
        echo -e "\033[32mMariaDB install successfully! \033[0m"
else
        echo -e "\033[31mMariaDB install failed, Please contact the author! \033[0m"
        kill -9 $$
fi

/bin/cp $mariadb_install_dir/support-files/mysql.server /etc/init.d/mysqld
sed -i "s@^basedir=.*@basedir=$mariadb_install_dir@" /etc/init.d/mysqld
sed -i "s@^datadir=.*@datadir=$mariadb_data_dir@" /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
OS_CentOS='chkconfig --add mysqld \n
chkconfig mysqld on'
OS_Debian_Ubuntu='update-rc.d mysqld defaults'
OS_command
cd ..

# my.cf
cat > /etc/my.cnf << EOF
[client]
port = 3306
socket = /tmp/mysql.sock

[mysqld]
port = 3306
socket = /tmp/mysql.sock

basedir = $mariadb_install_dir
datadir = $mariadb_data_dir
pid-file = $mariadb_data_dir/mysql.pid
user = mysql
bind-address = 0.0.0.0
server-id = 1

skip-name-resolve
#skip-networking
back_log = 300

max_connections = 1000
max_connect_errors = 6000
open_files_limit = 65535
table_open_cache = 128 
max_allowed_packet = 4M
binlog_cache_size = 1M
max_heap_table_size = 8M
tmp_table_size = 16M

read_buffer_size = 2M
read_rnd_buffer_size = 8M
sort_buffer_size = 8M
join_buffer_size = 8M
key_buffer_size = 4M

thread_cache_size = 8

query_cache_type = 1
query_cache_size = 8M
query_cache_limit = 2M

ft_min_word_len = 4

log_bin = mysql-bin
binlog_format = mixed
expire_logs_days = 30

log_error = $mariadb_data_dir/mysql-error.log
slow_query_log = 1
long_query_time = 1
slow_query_log_file = $mariadb_data_dir/mysql-slow.log

performance_schema = 0

#lower_case_table_names = 1

skip-external-locking

default_storage_engine = InnoDB
#default-storage-engine = MyISAM
innodb_file_per_table = 1
innodb_open_files = 500
innodb_buffer_pool_size = 64M
innodb_write_io_threads = 4
innodb_read_io_threads = 4
innodb_thread_concurrency = 0
innodb_purge_threads = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 2M
innodb_log_file_size = 32M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120

bulk_insert_buffer_size = 8M
myisam_sort_buffer_size = 8M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1

interactive_timeout = 28800
wait_timeout = 28800

[mysqldump]
quick
max_allowed_packet = 16M

[myisamchk]
key_buffer_size = 8M
sort_buffer_size = 8M
read_buffer = 4M
write_buffer = 4M
EOF

Memtatol=`free -m | grep 'Mem:' | awk '{print $2}'`
if [ $Memtatol -gt 1500 -a $Memtatol -le 2500 ];then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 16@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 16M@' /etc/my.cnf
        sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 16M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 16M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 128M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 32M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 256@' /etc/my.cnf
elif [ $Memtatol -gt 2500 -a $Memtatol -le 3500 ];then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 32@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 32M@' /etc/my.cnf
        sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 32M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 64M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 512M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 64M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 512@' /etc/my.cnf
elif [ $Memtatol -gt 3500 ];then
        sed -i 's@^thread_cache_size.*@thread_cache_size = 64@' /etc/my.cnf
        sed -i 's@^query_cache_size.*@query_cache_size = 64M@' /etc/my.cnf
        sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 64M@' /etc/my.cnf
        sed -i 's@^key_buffer_size.*@key_buffer_size = 256M@' /etc/my.cnf
        sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 1024M@' /etc/my.cnf
        sed -i 's@^tmp_table_size.*@tmp_table_size = 128M@' /etc/my.cnf
        sed -i 's@^table_open_cache.*@table_open_cache = 1024@' /etc/my.cnf
fi

$mariadb_install_dir/scripts/mysql_install_db --user=mysql --basedir=$mariadb_install_dir --datadir=$mariadb_data_dir

chown mysql.mysql -R $mariadb_data_dir
service mysqld start
export PATH=$mariadb_install_dir/bin:$PATH
[ -z "`cat /etc/profile | grep $mariadb_install_dir`" ] && echo "export PATH=$mariadb_install_dir/bin:\$PATH" >> /etc/profile 
. /etc/profile

$mariadb_install_dir/bin/mysql -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"$dbrootpwd\" with grant option;"
$mariadb_install_dir/bin/mysql -e "grant all privileges on *.* to root@'localhost' identified by \"$dbrootpwd\" with grant option;"
$mariadb_install_dir/bin/mysql -uroot -p$dbrootpwd -e "delete from mysql.user where Password='';"
$mariadb_install_dir/bin/mysql -uroot -p$dbrootpwd -e "delete from mysql.db where User='';"
$mariadb_install_dir/bin/mysql -uroot -p$dbrootpwd -e "delete from mysql.proxies_priv where Host!='localhost';"
$mariadb_install_dir/bin/mysql -uroot -p$dbrootpwd -e "drop database test;"
$mariadb_install_dir/bin/mysql -uroot -p$dbrootpwd -e "reset master;"
sed -i "s@^db_install_dir.*@db_install_dir=$mariadb_install_dir@" options.conf
sed -i "s@^db_data_dir.*@db_data_dir=$mariadb_data_dir@" options.conf
service mysqld stop
}
