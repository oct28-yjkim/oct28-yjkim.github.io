---
title: "Ceph ansible"
date: 2021-06-08T08:06:25+06:00
description: ceph installation with ansible
menu:
  sidebar:
    name: ceph-ansible
    identifier: ceph-ansible
    parent: Ceph
    weight: 30
author:
  name: yjkim
  image: /images/author/john.png
math: true
---

## 개요 

* Ceph 설치방법은 Ceph-ansible 이며  stable-3.2 버전을 이용하여 설치 하였다. 
* 설치 노드는 
    * mon 1, osd 3, mgr 1 이며 mon1 과 mgr1, osd1 이 같은 호스트에 배포가 되었다. 
    * ceph0 10.0.3.2 8cpu 16gb ram, /dev/sdb 300gb
    * ceph1 10.0.3.3 8cpu 16gb ram, /dev/sdb 300gb
    * ceph2 10.0.3.4 8cpu 16gb ram, /dev/sdb 300gb 


## ceph prerequirements

* 3node 부팅 Vagrant 로 부팅하면서 /dev/sdb/ 를 생성하도록 하였으며 lvm, fs 생성은 하지 않았다.
* ssh fingerprint 설정

```sh 
# 이방법으로 패스워드 yes, 패스워드 일일이 쳤음 
ssh-keygen 
ssh-copy-id ceph0
ssh-copy-id ceph1
ssh-copy-id ceph2

# 핑거프린트 검증용 각 호스트 접속 조회 확인  
ssh root@ceph0 hostname
ssh root@ceph1 hostname
ssh root@ceph2 hostname


# 다른방법으로는 sshpass 가 있다고 한다. 아래와 같이 사용하면 된다. 
yum install -y sshpass
echo "passwd-content" ~/passwd
sshpass -f ~/passwd ssh-copy-id root@ceph0
ssh root@ceph0 hostname 
```

* ceph 설치 전 사전 준비 
    * Pip, git Clone, 의존성 파일을 받아준다. 

```sh 
yum install -y git python-pip sshpass && 
git clone https://github.com/ceph/ceph-ansible.git && \
cd ceph-ansible && \
git checkout  stable-3.2 && \
pip install -r requirements.txt 
```

* /etc/hosts 설정
```sh
cat <<EOF>> /etc/hosts

10.0.3.2 ceph0
10.0.3.3 ceph1
10.0.3.4 ceph2

EOF

# 검증하기위한 조회 
cat /etc/hosts

# ceph 
firewall-cmd --permanent --new-service 3300 && \
  firewall-cmd --permanent --new-service 6789 && \
  firewall-cmd --reload

```




## ceph ansible install

* inventory 작성 

```sh 
cat << EOF | tee inventory.ini
[mons]
ceph0

[mgrs]
ceph0

[osds]
ceph0
ceph1
ceph2

[grafana-server]
ceph0

[all:children]
mons
osds
mgrs
EOF
```

* extra-vars.yml 파일 작성 

```sh 

cat <<EOF | tee extra.yaml
# ceph
monitor_interface: eth1
monitor_address: 10.0.3.2
public_network: 10.0.3.0/24
cluster_network: 10.0.3.0/24

ceph_origin: repository
ceph_repository: community
ceph_stable_release: luminous

ceph_conf_overrides:
  global:
    mon_allow_pool_delete: true
    osd_pool_default_size: 1
    osd_pool_default_min_size: 1
    osd_pg_stat_report_internal_max: 1
  osd:
    osd_min_pg_log_entries: 10
    osd_max_pg_log_entries: 10
    osd_pg_log_dups_tracked: 10
    osd_pg_log_trim_min: 10

osd_objectstore: bluestore
#lvm_volumes:
#  - data: /dev/sda
#  - data: /dev/sdb
osd_scenario: collocated
dmcrypt: true
devices:
  - /dev/sdb

openstack_config: true
kube_pool:
  name: "kube"
  pg_num: 64
  pgp_num: 64
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
  application: "rbd"
openstack_glance_pool:
  name: "images"
  pg_num: 64
  pgp_num: 64
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
openstack_cinder_pool:
  name: "volumes"
  pg_num: 64
  pgp_num: 64
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
openstack_cinder_backup_pool:
  name: "backups"
  pg_num: 2
  pgp_num: 2
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
openstack_nova_vms_pool:
  name: "vms"
  pg_num: 64
  pgp_num: 64
  rule_name: "replicated_rule"
  type: 1
  erasure_profile: ""
  expected_num_objects: ""
  application: "rbd"

openstack_pools:
  - "{{ kube_pool }}"
  - "{{ openstack_glance_pool }}"
  - "{{ openstack_cinder_pool }}"
  - "{{ openstack_cinder_backup_pool }}"
  - "{{ openstack_nova_vms_pool }}"
EOF

```



* ping 체크 

``` sh 
ansible -b -i inventory.ini -m ping all
```

* ansible playbook site 스크립트를 실행하여 설치 

```sh 

 cp site.yml.sample site.yml

INVENTORY="-i inventory.ini"
EXTRA="-e @extra.yaml"
OPTION="-b -vvvv"
PLAY="site.yml"
ansible-playbook $INVENTORY $EXTRA $PLAY $OPTION 
# ansible-playbook -b -vvvv -i inventory.ini -e @extra.yaml site.yaml

```


## ceph ansible remove 

```sh 

cat << EOF | tee purge=cluster.sh 
#!/bin/bash 
set -ex 
INVENTORY="-i inventory.ini"
EXTRA="-e @extra.yaml"
PLAY="infrastructure-playbooks/purge-cluster.yml"
OPTION="-b -vvv"
ansible-playbook $INVENTORY $EXTRA $PLAY $OPTION 
EOF
chmod +x purge=cluster.sh  && purge=cluster.sh

```


## 주로 발생한 Error 

* /etc/ceph.conf 의 mon host 값 문제 
    * ceph-ansible 4.0 버전의 Source 는 task 파일의 Jinja template 를 확인해보면 
    * mon 호스트를 루프 돌면서 호스트 정보를 찍어주는데 
    * mon v2, v1 버전을 마이그래이션 하는 소스가 들어가있다.
    * 그렇기때문에 git 다운받고 checkout stable-3.2 버전으로 실행시키며
    * extra.yaml 에 monitor_address 값을 넣어준다. 
* 에러내용 
```sh
fatal: [mon1]: FAILED! => 
  msg: |-
    The conditional check '(ceph_health_raw.stdout != "") and (ceph_health_raw.stdout | default('{}') | from_json)['state'] in ['leader', 'peon']
    ' failed. The error was: No JSON object could be decoded
```
* 조치사항 
```sh 
#조치 1 branch checkout 
$ git checkout stable-3.2

$ vi extre.yaml
---
# extra.yaml 
monitor_interface: eth1
#monitor_address: 10.0.3.2 ## 조치 2 여기부분
public_network: 10.0.3.0/24
cluster_network: 10.0.3.0/24
---

* 참고  : https://github.com/ceph/ceph-ansible/issues/3948
* 참고2 : http://lists.ceph.com/pipermail/ceph-users-ceph.com/2019-February/032801.html
```
