---
title: "Ceph commands"
date: 2021-06-08T08:06:25+06:00
description: ceph commands
menu:
  sidebar:
    name: ceph-commands
    identifier: ceph-commands
    parent: Ceph
    weight: 30
author:
  name: yjkim
  image: /images/author/john.png
math: true
---


## ceph status 

* Ceph mon 으로 저장이된 Ceph cluster 상태를 보여주는 명령어

```sh 

[root@ceph0 ~]# ceph -s
  cluster:
    id:     0ad3892c-c903-44d3-8872-b7536d10bcdb
    health: HEALTH_OK

  services:
    mon: 1 daemons, quorum ceph0
    mgr: ceph0(active)
    osd: 3 osds: 3 up, 3 in

  data:
    pools:   5 pools, 258 pgs
    objects: 0 objects, 0B
    usage:   3.01GiB used, 897GiB / 900GiB avail
    pgs:     258 active+clean

# watch cluster health
[root@ceph0 ~]# ceph -w
  cluster:
    id:     0ad3892c-c903-44d3-8872-b7536d10bcdb
    health: HEALTH_OK

  services:
    mon: 1 daemons, quorum ceph0
    mgr: ceph0(active)
    osd: 3 osds: 3 up, 3 in

  data:
    pools:   5 pools, 258 pgs
    objects: 0 objects, 0B
    usage:   3.01GiB used, 897GiB / 900GiB avail
    pgs:     258 active+clean


[root@ceph0 ~]# ceph health detail
HEALTH_OK


[root@ceph0 ~]# ceph quorum_status --format json-pretty

{
    "election_epoch": 3,
    "quorum": [
        0
    ],
    "quorum_names": [
        "ceph0"
    ],
    "quorum_leader_name": "ceph0",
    "monmap": {
        "epoch": 1,
        "fsid": "0ad3892c-c903-44d3-8872-b7536d10bcdb",
        "modified": "2019-09-29 03:37:04.511632",
        "created": "2019-09-29 03:37:04.511632",
        "features": {
            "persistent": [
                "kraken",
                "luminous"
            ],
            "optional": []
        },
        "mons": [
            {
                "rank": 0,
                "name": "ceph0",
                "addr": "10.0.3.2:6789/0",
                "public_addr": "10.0.3.2:6789/0"
            }
        ]
    }
}

```

## ceph mon  

* Ceph monitor 의 정보를 dump 출력한다. 

```sh 

[root@ceph0 ~]# ceph mon dump
dumped monmap epoch 1
epoch 1
fsid 0ad3892c-c903-44d3-8872-b7536d10bcdb
last_changed 2019-09-29 03:37:04.511632
created 2019-09-29 03:37:04.511632
0: 10.0.3.2:6789/0 mon.ceph0

```

## ceph df 

* ceph osd 의 사용량을 출력해준다. 

```sh 

[root@ceph0 ~]# ceph df
GLOBAL:
    SIZE       AVAIL      RAW USED     %RAW USED
    900GiB     897GiB      3.01GiB          0.33
POOLS:
    NAME        ID     USED     %USED     MAX AVAIL     OBJECTS
    kube        1        0B         0        852GiB           0
    images      2        0B         0        852GiB           0
    volumes     3        0B         0        852GiB           0
    backups     4        0B         0        852GiB           0
    vms         5        0B         0        852GiB           0

```

## ceph instence status 

```sh

[root@ceph0 ~]# ceph mon stat
e1: 1 mons at {ceph0=10.0.3.2:6789/0}, election epoch 3, leader 0 ceph0, quorum 0 ceph0
[root@ceph0 ~]# ceph osd stat
3 osds: 3 up, 3 in
[root@ceph0 ~]# ceph osd pool stats
pool kube id 1
  nothing is going on

pool images id 2
  nothing is going on

pool volumes id 3
  nothing is going on

pool backups id 4
  nothing is going on

pool vms id 5
  nothing is going on

[root@ceph0 ~]# ceph pg stat
258 pgs: 258 active+clean; 0B data, 3.01GiB used, 897GiB / 900GiB avail

```

## ceph pg dump 

```sh 

[root@ceph0 ~]# ceph pg dump
dumped all
version 14056
stamp 2019-09-29 11:27:59.810412
last_osdmap_epoch 0
last_pg_scan 0
full_ratio 0
nearfull_ratio 0
PG_STAT OBJECTS MISSING_ON_PRIMARY DEGRADED MISPLACED UNFOUND BYTES LOG DISK_LOG STATE        STATE_STAMP                VERSION REPORTED UP  UP_PRIMARY ACTING ACTING_PRIMARY LAST_SCRUB SCRUB_STAMP                LAST_DEEP_SCRUB DEEP_SCRUB_STAMP           SNAPTRIMQ_LEN
5.3b          0                  0        0         0       0     0   0        0 active+clean 2019-09-29 03:41:54.178434     0'0    20:16 [2]          2    [2]              2        0'0 2019-09-29 03:41:53.161934             0'0 2019-09-29 03:41:53.161934             0
1.3f          0                  0        0         0       0     0   0        0 active+clean 2019-09-29 03:41:48.162380     0'0    20:21 [0]          0    [0]              0        0'0 2019-09-29 03:41:46.562216             0'0 2019-09-29 03:41:46.562216             0
2.3c          0                  0        0         0       0     0   0        0 active+clean 2019-09-29 03:41:49.881971     0'0    20:20 [0]          0    [0]              0        0'0 2019-09-29 03:41:48.150236             0'0 2019-09-29 03:41:48.150236             0
...
...
...

1.2d          0                  0        0         0       0     0   0        0 active+clean 2019-09-29 03:41:48.162526     0'0    20:21 [0]          0    [0]              0        0'0 2019-09-29 03:41:46.562216             0'0 2019-09-29 03:41:46.562216             0
2.2e          0                  0        0         0       0     0   0        0 active+clean 2019-09-29 03:41:49.881875     0'0    20:20 [0]          0    [0]              0        0'0 2019-09-29 03:41:48.150236             0'0 2019-09-29 03:41:48.150236             0
3.2f          0                  0        0         0       0     0   0        0 active+clean 2019-09-29 03:41:51.531982     0'0    20:18 [2]          2    [2]              2        0'0 2019-09-29 03:41:49.863122             0'0 2019-09-29 03:41:49.863122             0

5 0 0 0 0 0 0 0 0
4 0 0 0 0 0 0 0 0
3 0 0 0 0 0 0 0 0
2 0 0 0 0 0 0 0 0
1 0 0 0 0 0 0 0 0

sum 0 0 0 0 0 0 0 0
OSD_STAT USED    AVAIL  TOTAL  HB_PEERS PG_SUM PRIMARY_PG_SUM
0        1.00GiB 299GiB 300GiB    [1,2]     89             89
2        1.00GiB 299GiB 300GiB    [0,1]     88             88
1        1.00GiB 299GiB 300GiB    [0,2]     81             81
sum      3.01GiB 897GiB 900GiB

```

## ceph osd pool ls detail 

```sh 

[root@ceph0 ~]# ceph osd pool ls detail
pool 1 'kube' replicated size 1 min_size 1 crush_rule 0 object_hash rjenkins pg_num 64 pgp_num 64 last_change 20 flags hashpspool stripe_width 0 expected_num_objects 1 application rbd
pool 2 'images' replicated size 1 min_size 1 crush_rule 0 object_hash rjenkins pg_num 64 pgp_num 64 last_change 16 flags hashpspool stripe_width 0 expected_num_objects 1
pool 3 'volumes' replicated size 1 min_size 1 crush_rule 0 object_hash rjenkins pg_num 64 pgp_num 64 last_change 17 flags hashpspool stripe_width 0 expected_num_objects 1
pool 4 'backups' replicated size 1 min_size 1 crush_rule 0 object_hash rjenkins pg_num 2 pgp_num 2 last_change 18 flags hashpspool stripe_width 0 expected_num_objects 1
pool 5 'vms' replicated size 1 min_size 1 crush_rule 0 object_hash rjenkins pg_num 64 pgp_num 64 last_change 21 flags hashpspool stripe_width 0 expected_num_objects 1 application rbd

```

## ceph osd tree 

```sh 

[root@ceph0 ~]# ceph osd tree
ID CLASS WEIGHT  TYPE NAME      STATUS REWEIGHT PRI-AFF
-1       0.87868 root default
-3       0.29289     host ceph0
 1   hdd 0.29289         osd.1      up  1.00000 1.00000
-7       0.29289     host ceph1
 2   hdd 0.29289         osd.2      up  1.00000 1.00000
-5       0.29289     host ceph2
 0   hdd 0.29289         osd.0      up  1.00000 1.00000

```

## ceph osd df 

```sh 

[root@ceph0 ~]# ceph osd df
ID CLASS WEIGHT  REWEIGHT SIZE   USE     AVAIL  %USE VAR  PGS
 1   hdd 0.29289  1.00000 300GiB 1.00GiB 299GiB 0.33 1.00  81
 2   hdd 0.29289  1.00000 300GiB 1.00GiB 299GiB 0.33 1.00  88
 0   hdd 0.29289  1.00000 300GiB 1.00GiB 299GiB 0.33 1.00  89
                    TOTAL 900GiB 3.01GiB 897GiB 0.33
MIN/MAX VAR: 1.00/1.00  STDDEV: 0

```

## ceph auth list 

```sh 

[root@ceph0 ~]# ceph auth list
installed auth entries:

osd.0
        key: AQA7qY9duVoVFRAA9xe7JGxNo5n2vPWSX1Y+ug==
        caps: [mgr] allow profile osd
        caps: [mon] allow profile osd
        caps: [osd] allow *
...
...
...
mgr.ceph0
        key: AQBaqI9dAAAAABAAC73UDhKvlug07VlAI35D5Q==
        caps: [mds] allow *
        caps: [mon] allow profile mgr
        caps: [osd] allow *

```