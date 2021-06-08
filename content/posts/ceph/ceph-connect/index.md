---
title: "Ceph connect"
date: 2021-06-08T08:06:25+06:00
description: ceph connect
menu:
  sidebar:
    name: ceph-connect
    identifier: ceph-connect
    parent: Ceph
    weight: 30
author:
  name: yjkim
  image: /images/author/john.png
math: true
---

## file system 

### 작업순서 

* mds deploy 
  * 예시에는 cephadm 으로 mds 를 스케줄 배포 하였습니다. 
* ceph file system 에 사용될 pool 을 생성한다. 
  * inode, tree 정보가 들어갈 metadata pool
  * data 가 들어갈 data pool 생성 

* Client 를 이용하여 file system 사용 


### create replicated pool 

```sh 

ceph orch apply mds cephfs --placement="ceph0,ceph1,ceph2"

FS_NAME=cephfs_repl_data
FS_META=cephfs_repl_meta
PG_CNT=8
ceph osd pool create ${FS_NAME} ${PG_CNT}
ceph osd pool create ${FS_META} ${PG_CNT}
ceph fs new cephfs ${FS_META} ${FS_NAME}

[root@ceph-test mnt]# ceph fs status
cephfs - 0 clients
======
RANK  STATE           MDS             ACTIVITY     DNS    INOS  
 0    active  cephfs.ceph1.witvio  Reqs:    0 /s    10     13   
      POOL          TYPE     USED  AVAIL  
cephfs_repl_meta  metadata  1536k   410G  
cephfs_repl_data    data       0    410G  
    STANDBY MDS      
cephfs.ceph2.iplnaa  
cephfs.ceph0.fpvsgg  
MDS version: ceph version 15.2.3 (d289bbdec69ed7c1f516e0a093594580a76b78d0) octopus (stable)

[root@ceph-test mnt]# ceph auth get client.admin | grep key 
exported keyring for client.admin
	key = AQDk/NleJfSOExAAKHtFWBmEDdNCLc/WGLFUaQ==

mount.ceph ceph1,ceph0,ceph2:/ /mnt/cephfs-repl -o name=admin,secret=AQDk/NleJfSOExAAKHtFWBmEDdNCLc/WGLFUaQ==

```


### erasure code pool 


```sh 

# deploy mds 
ceph orch apply mds cephfs --placement="ceph0,ceph1,ceph2"

FS_NAME=cephfs_era_data
FS_META=cephfs_era_meta
PG_CNT=8
ceph osd pool create ${FS_NAME} erasure
ceph osd pool create ${FS_META} ${PG_CNT}
ceph osd pool create cephfs_data ${PG_CNT}
# ceph fs 의 erasure code pool 을 사용하기 위하여는 해당 옵션을 enable 하여야 한다. 
ceph osd pool set ${FS_NAME} allow_ec_overwrites true
ceph osd pool application enable ${FS_NAME} cephfs

ceph fs new cephfs ${FS_META} ${FS_NAME} --force 

# ceph status 의 mds 의 active 가 앞으로 오게한다. 
mount.ceph ceph1,ceph0,ceph2:/ /mnt/cephfs-era -o name=admin,secret=AQDk/NleJfSOExAAKHtFWBmEDdNCLc/WGLFUaQ==
```


## RBD 


* ceph pool 생성 
* client mount 
* benchmark 

* ceph 의 pool 종류는 replicated, erasure 2가지 형태가 있다. 


### ceph create replicated pool 

```sh

# pg calcualte exp : 100 = (3 * 100) / 3
## 대략 7.x 가 나와서 default 옵션인 8로 진행 
##             (OSDs * 100)
##Total PGs =  ------------
##              pool size
ceph osd pool create rbd_repl_bench 8 8 

# rbd create \
# ${IMAGE_NAME:=img_repl_bench} \
# --size ${10G, 1024:default unit is MB} \
# --pool ${POOL_NAME:=rbd_repl_bench}
rbd create img_repl_bench --size 102400 --pool rbd_repl_bench

# rbd 의 기능을 비활성 화 하여야만이 image 를 host 에 map 할 수 있다. 
rbd feature disable rbd_repl_bench/img_repl_bench object-map fast-diff deep-flatten

# host 에 map 한다. 
## mapping 시에 mod_probe 의 rbd 가 enable 되어있어야 하며 
## linux 의 kernal rbd 가 호스트에 bus 를 생성하여서 통신한다. 
rbd map rbd_repl_bench/img_repl_bench 

mkfs.xfs /dev/rbd2

mkdir -p /mnt/rbd-repl/

fstrim -v /mnt/rbd-repl

# benchmark script 직접 돌려보기 바란다. 
rbd bench --io-type write rbd_repl_bench/img_repl_bench  --io-size 4M --rbd-cache=false 
rbd bench rbd_repl_bench/img_repl_bench  --io-type write --io-size 4M --io-threads 16 --io-total 10G --io-pattern rand --rbd-cache=false 
date; time dd if=/dev/zero of=./testfile bs=1G count=5 oflag=dsync; sync; rm -rf testfile ; sync; date; fstrim -v /mnt/rbd-repl;

# 호스트의 disk 를 쓰고있는지 모니터링 하는 스크립트 
iostat -xkdzt /dev/sdb /dev/sdc /dev/sdd /dev/sde 1 | tee rbd-map-repl.txt

# rbd mapped image 에 write 한 후에 데이터를 삭제할 경우에 rados 를 이용하여 조회하면 pool 내에는 데이터가 그대로 있다. 
# scrub 옵션을 활성화 하여야 하며 manually 하게 pool 의 데이터를 삭제하려면 아래 커맨드를 실행 한다.
# disk 의 trim 기능이 잇어야 한다고 한다. 최신 ssd 의 경우 보장하지만 회사 서버는 그리 최신이 아니여서 수동으로 진행한다. 
# fstrim -v ${TRIM_POINT}
fstrim -v /mnt/rbd-repl

```

### ceph create erasure code pool 

```sh 

# erasure coded pool 의 경우 metadata pool 과 data pool 이 필요하다. 
# erasure code profile 의 경우 default 옵션으로 진행한다.
ceph osd pool create rbd_erasure_meta_bench 8 8 
ceph osd pool create rbd_erasure_bench erasure

# rbd image 로 사용하기 위한 옵션 enable 
ceph osd pool set rbd_erasure_bench allow_ec_overwrites true

# rbd image create 
rbd create --size 100G --data-pool rbd_erasure_bench rbd_erasure_meta_bench/img_erasure_bench

# rbd mapping 하기 위한 옵션 disable 처리 
rbd feature disable rbd_erasure_meta_bench/img_erasure_bench object-map fast-diff deep-flatten

# rbd image 를 호스트에 mapping 한다. 
rbd map rbd_erasure_meta_bench/img_erasure_bench

# file system 생성 : recommand option 인 xfs 로 생성 
mkfs.xfs /dev/rbd1

# mount point mkdir 
mkdir -p /mnt/rbd-era/

# mount 
mount /dev/rbd1 /mnt/rbd-era/

# benchamrk script 
rados bench -p rbd_repl_bench 10 write --no-cleanup
rados -p rbd_repl_bench cleanup
rados bench -p rbd_erasure_bench 10 write --no-cleanup
rados -p rbd_erasure_bench cleanup
dd if=/dev/zero of=./testfile bs=1G count=5 oflag=dsync  
date; time dd if=/dev/zero of=./testfile bs=1G count=5 oflag=dsync; sync; rm -rf testfile ; sync; date;

# sampling scripts 

iostat -xkdzt -p ALL 1
iostat -xkdzt  /dev/sdc 1
iostat -xkdzt /dev/sdb /dev/sdc /dev/sdd /dev/sde 1 | tee ceph-bench.txt
iostat -xkcdzt /dev/sdc /dev/sdd /dev/sde 1 | tee ceph-bench.txt

```
