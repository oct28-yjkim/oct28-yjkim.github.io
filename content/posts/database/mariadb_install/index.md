---
title: "On-Premise 서버에 MariaDB 설치하기 "
date: 2021-07-06T08:06:25+09:00
description: MariaDB 설치 
menu:
  sidebar:
    name: MariaDB_install
    identifier: MariaDB_install
    parent: Database
    weight: 20
author:
  name: yjkim
  image: /images/author/john.png
math: true
---

### 개요 

* 2EA 의 서버에 Replication 을 구성하는 예제를 작성할 것이다. 
* 서버는 
  * mysql1 : 192.168.12.131, 8 core, 16GB RAM, Disk 500Gib
  * mysql2 : 192.168.12.132, 8 core, 16GB RAM, Disk 500Gib 

### MariaDB 설치 

* 설치는 Compile 설치가 가장 베스트이며 성능차이가 있다고 하지만.. 현 기준으로는 RPM 설치를 하겠다. 
* 순서는 아래 순차적으로 진행하겠다. 
  * RPM repo 구성 
  * MariaDB 설치 
  * Data Partition 구성 
  * Replication 설정 

```sh 
cat << EOF >  /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

sudo yum clean all

sudo rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB

sudo yum install -y MariaDB-server galera MariaDB-client MariaDB-shared MariaDB-backup MariaDB-common

Installing:
 MariaDB-backup                      x86_64             10.3.30-1.el7.centos              mariadb             6.1 M
 MariaDB-client                      x86_64             10.3.30-1.el7.centos              mariadb              11 M
 MariaDB-common                      x86_64             10.3.30-1.el7.centos              mariadb              81 k
 MariaDB-compat                      x86_64             10.3.30-1.el7.centos              mariadb             2.2 M
     replacing  mariadb-libs.x86_64 1:5.5.65-1.el7
 MariaDB-server                      x86_64             10.3.30-1.el7.centos              mariadb              24 M
 MariaDB-shared                      x86_64             10.3.30-1.el7.centos              mariadb             112 k
 galera                              x86_64             25.3.33-1.el7.centos              mariadb             8.1 M
Installing for dependencies:
 boost-program-options               x86_64             1.53.0-28.el7                     base                156 k
 lsof                                x86_64             4.87-6.el7                        base                331 k
 perl-Compress-Raw-Bzip2             x86_64             2.061-3.el7                       base                 32 k
 perl-Compress-Raw-Zlib              x86_64             1:2.061-4.el7                     base                 57 k
 perl-DBI                            x86_64             1.627-4.el7                       base                802 k
 perl-IO-Compress                    noarch             2.061-2.el7                       base                260 k
 perl-Net-Daemon                     noarch             0.48-5.el7                        base                 51 k
 perl-PlRPC                          noarch             0.2020-14.el7                     base                 36 k

```

* 설치 요구 받은 서버의 버전정보가 10.3 이며 각 서버별로의 기능 특성을 숙지 하는게 중요 하다. 
* 설치 하고자 하는 버전의 정보를 명시 하려면 RPM Repo 에 baseurl 에 버전정보를 따라가도록 설정하면 된다. 

### Data Partition 준비 

* DB 서버를 구성 할때는 OS 영역과 Data 영역을 분리 하는것을 권장 한다. 
* Disk 의 Bandwidth 가 별도로 영향을 받도록 정의 하는것이 중요하며 
* OS 에 받는 부하와 DB 가 받는 부하를 분리 하여서 DB 가 장애나도 OS 는 유지되어 복구 가능한 상태로 유지하는것이 중요 하다. 
* 그리고 OS 에서 사용하는 Disk 는 그렇게 비싸지 않아도 되지만 거의 Mirror 수준인 RAID 1 수준으로 유지하지만 
* Data Disk 는 장비에 따라 RAID 5, 6, 혹은 10 등등의 구조를 가저가서 물리장비인 Disk Controller 에서 복구 하기도 한다. 
* 당연히 DB 가 장애가 나서 데이터를 저장 하지 못하여도 Active, Active 혹은 Active Standby 형태로 구성하여 Failover 을 고려 하는것도 중요하다. 

```sh 
fdisk /dev/vdb
n
p
enter * 3 
w
mkfs.xfs /dev/vdb1
mkdir /data
# 영구히 마운트 하려면 /etc/fstab 에 기록해준다. 
mount /dev/vdb1 /data
mkdir -p /data/mysql
mkdir -p /data/mysql/mysql-data
mkdir -p /data/mysql/tmpdir
mkdir -p /data/mysql/log
mkdir -p /data/mysql/log/binary
mkdir -p /data/mysql/log/error
mkdir -p /data/mysql/log/relay
mkdir -p /data/mysql/log/general

chown -R mysql:mysql /data/mysql/
```

### Data Path 변경 

* MariaDB 를 설치하면 기본 Dir 에 데이터가 저장이 되며 기본 경로는 OS 파티션에 위치한다
* MariaDB 의 Data Path 를 변경 해준다. 

```sh 

rm -rf /var/lib/mysql 

cat << EOF >  /etc/my.cnf
[client]
port                            = 3306
socket                          = /data/mysql/mysql.sock

[mysqld]
port                            = 3306
socket                          = /data/mysql/mysql.sock

datadir                         = /data/mysql/mysql-data
tmpdir                          = /data/mysql/tmpdir
innodb_data_home_dir           = /data/mysql/mysql-data
innodb_log_group_home_dir       = /data/mysql/log

binlog_format                   = mixed
expire_logs_days                = 7
long_query_time                 = 10
max_binlog_size                 = 1G
sync_binlog                     = 1
slow_query_log                  = 1
log-bin                         = /data/mysql/log/binary/mysql-bin
log-error                       = /data/mysql/log/error/mysql.err
relay-log                       = /data/mysql/log/relay/relay-log
slow_query_log_file             = /data/mysql/log/mysql-slow-query.log
general_log_file                = /data/mysql/log/general/mysql_general.log
log-warnings                    = 2

character_set-client-handshake  = FALSE
character-set-server            = utf8mb4
collation_server                = utf8mb4_general_ci
init_connect                    = set collation_connection=utf8mb4_general_ci
init_connect                    = set names utf8mb4

back_log                        = 1024
binlog_cache_size               = 1M
ft_min_word_len                 = 4
interactive_timeout             = 600
join_buffer_size                = 2M
max_allowed_packet              = 1G
max_connections                 = 8196
max_heap_table_size             = 4096M
max_length_for_sort_data        = 1024
open_files_limit                = 8192
performance_schema
read_buffer_size                = 1M
read_rnd_buffer_size            = 8M
skip_external_locking
skip-name-resolve               = 1
sort_buffer_size                = 1M
key_buffer_size                 = 8388608
table_open_cache                = 10240
tmp_table_size                  = 4096M
transaction_isolation           = READ-COMMITTED
slave_skip_errors               = all

query_cache_type                = 0
query_cache_size                = 0

innodb_autoinc_lock_mode        = 1
innodb_buffer_pool_size         = 1G # 적절한 수준으로 조정 한다. 
innodb_fast_shutdown            = 1
innodb_file_per_table           = 1
innodb_flush_log_at_trx_commit  = 2

innodb_lock_wait_timeout        = 72000
innodb_log_buffer_size          = 64M
innodb_log_file_size            = 512M
innodb_log_files_in_group       = 8
innodb_open_files               = 8192
innodb_read_io_threads          = 8
innodb_thread_concurrency       = 0
innodb_thread_sleep_delay       = 0
innodb_write_io_threads         = 8

thread_handling=pool-of-threads
thread_pool_idle_timeout        = 120
thread_pool_stall_limit         = 60

log_bin_trust_function_creators = 1

server-id                       = 1 # Replication 하고자 하는 서버의 식벌 정보를 준다. 

[mysqldump]
quick
max_allowed_packet              = 512M
EOF

# 초기 Database 파일을 생성 해준다. 
/usr/bin/mysql_install_db --user=mysql

# Selinux 가 Enable 되었을 시에 Data 폴더를 적용 해준다. 
semanage fcontext -a -t mysqld_db_t "/data/mysql(/.*)?"
restorecon -R -v /data/mysql 

# MariaDB 를 시작 한다. 
Systmectl start maraidb && systemctl enable mariadb

```

### MariaDB Replication 설정 

```sh 

# 각 서버 별로 계정 설정을 해준다. 
CREATE USER 'repl'@'%' IDENTIFIED BY 'yjkim1234!';
GRANT REPLICATION SLAVE ON *.* to 'repl';

# master 서버에서 master 의 bin log 파일 정보를 확인한다. 
MariaDB [(none)]> show master status;
+------------------+----------+--------------+------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
+------------------+----------+--------------+------------------+
| mysql-bin.000012 |      342 |              |                  |
+------------------+----------+--------------+------------------+

# Slave 서버에서 Master 로 호출 한다. 
CHANGE MASTER TO MASTER_HOST='192.168.12.131', MASTER_USER='repl', MASTER_PASSWORD='yjkim1234!', MASTER_LOG_FILE='mysql-bin.000012', MASTER_LOG_POS=342;

# SLAVE 에서 조회 
MariaDB [(none)]> show slave status\G
*************************** 1. row ***************************
                Slave_IO_State:
                   Master_Host: 192.168.12.131
                   Master_User: repl
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: mysql-bin.000012
           Read_Master_Log_Pos: 342
                Relay_Log_File: relay-log.000001
                 Relay_Log_Pos: 4
         Relay_Master_Log_File: mysql-bin.000012
              Slave_IO_Running: No                 # 아직 동작중이 아니다. 
             Slave_SQL_Running: No
               Replicate_Do_DB:
           Replicate_Ignore_DB:
            Replicate_Do_Table:
        Replicate_Ignore_Table:
       Replicate_Wild_Do_Table:
   Replicate_Wild_Ignore_Table:
                    Last_Errno: 0
                    Last_Error:
                  Skip_Counter: 0
           Exec_Master_Log_Pos: 342
               Relay_Log_Space: 256
               Until_Condition: None
                Until_Log_File:
                 Until_Log_Pos: 0
            Master_SSL_Allowed: No
            Master_SSL_CA_File:
            Master_SSL_CA_Path:
               Master_SSL_Cert:
             Master_SSL_Cipher:
                Master_SSL_Key:
         Seconds_Behind_Master: NULL
 Master_SSL_Verify_Server_Cert: No
                 Last_IO_Errno: 0
                 Last_IO_Error:
                Last_SQL_Errno: 0
                Last_SQL_Error:
   Replicate_Ignore_Server_Ids:
              Master_Server_Id: 0
                Master_SSL_Crl:
            Master_SSL_Crlpath:
                    Using_Gtid: No
                   Gtid_IO_Pos:
       Replicate_Do_Domain_Ids:
   Replicate_Ignore_Domain_Ids:
                 Parallel_Mode: conservative
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State:
              Slave_DDL_Groups: 0
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0
1 row in set (0.000 sec)

# Slave 를 시작한다. 
START SLAVE;

# 동작 상태를 확인 
MariaDB [(none)]> show slave status\G
*************************** 1. row ***************************
                Slave_IO_State: Waiting for master to send event
                   Master_Host: 192.168.12.131
                   Master_User: repl
                   Master_Port: 3306
                 Connect_Retry: 60
               Master_Log_File: mysql-bin.000012
           Read_Master_Log_Pos: 342
                Relay_Log_File: relay-log.000002
                 Relay_Log_Pos: 555
         Relay_Master_Log_File: mysql-bin.000012
              Slave_IO_Running: Yes
             Slave_SQL_Running: Yes
               Replicate_Do_DB:
           Replicate_Ignore_DB:
            Replicate_Do_Table:
        Replicate_Ignore_Table:
       Replicate_Wild_Do_Table:
   Replicate_Wild_Ignore_Table:
                    Last_Errno: 0
                    Last_Error:
                  Skip_Counter: 0
           Exec_Master_Log_Pos: 342
               Relay_Log_Space: 858
               Until_Condition: None
                Until_Log_File:
                 Until_Log_Pos: 0
            Master_SSL_Allowed: No
            Master_SSL_CA_File:
            Master_SSL_CA_Path:
               Master_SSL_Cert:
             Master_SSL_Cipher:
                Master_SSL_Key:
         Seconds_Behind_Master: 0
 Master_SSL_Verify_Server_Cert: No
                 Last_IO_Errno: 0
                 Last_IO_Error:
                Last_SQL_Errno: 0
                Last_SQL_Error:
   Replicate_Ignore_Server_Ids:
              Master_Server_Id: 1
                Master_SSL_Crl:
            Master_SSL_Crlpath:
                    Using_Gtid: No
                   Gtid_IO_Pos:
       Replicate_Do_Domain_Ids:
   Replicate_Ignore_Domain_Ids:
                 Parallel_Mode: conservative
                     SQL_Delay: 0
           SQL_Remaining_Delay: NULL
       Slave_SQL_Running_State: Slave has read all relay log; waiting for the slave I/O thread to update it
              Slave_DDL_Groups: 0
Slave_Non_Transactional_Groups: 0
    Slave_Transactional_Groups: 0

```

### Replication 테스트 

```sh 

# master 에서 입력 한다. 
MariaDB [(none)]>  CREATE DATABASE REPLTEST;
Query OK, 1 row affected (0.003 sec)

MariaDB [(none)]> CREATE TABLE REPLTEST.REP(ID INT);
Query OK, 0 rows affected (0.008 sec)

MariaDB [(none)]> INSERT INTO REPLTEST.REP VALUES(1),(2),(3);
Query OK, 3 rows affected (0.003 sec)
Records: 3  Duplicates: 0  Warnings: 0

# slave 에서 조회 한다. 
MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| REPLTEST           |
| information_schema |
| mysql              |
| performance_schema |
| test               |
+--------------------+
5 rows in set (0.013 sec)

MariaDB [(none)]> select * from REPLTEST.REP;
+------+
| ID   |
+------+
|    1 |
|    2 |
|    3 |
+------+
3 rows in set (0.000 sec)


```