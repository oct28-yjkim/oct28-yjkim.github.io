---
title: "Kubernetes install with kubespray"
date: 2021-06-08T08:06:25+06:00
description: how to install k8s with kubespray
menu:
  sidebar:
    name: kubespray
    identifier: kubespray
    parent: Kubernetes
    weight: 20
author:
  name: yjkim
  image: /images/author/john.png
math: true
---

## 개요 

오늘은 K8s Cluster 을 간략하게 생성 해보는 예제를 기록해 보려고 한다. 
Cluster 생성은 Kubespray 프로젝트를 이용하여 생성할 예정이다. 

## 클러스터 정보 

* vm 생성 : vagrant 
* 호스트 정보 
    * k8s-master : 10.0.3.2
    * k8s-node1 : 10.0.3.3
    * k8s-node2  : 10.0.3.4
* single master, 2 node 

## 사전 설치 

* 사전설치 요소에는 아래와 같다. 
    * pip 설치 
    * kubespray 프로젝트 클론 
    * ansible 설치 : pip install 하면 설치됨  
* 나머지 sshd, user account,  host 설정은 skip 한다. 

```sh 
$ sudo yum install -y git python-pip 
$ git clone https://github.com/kubernetes-sigs/kubespray
$ pip install  -r kubespray/requirements.txt
```

* ssh fingerprint 관련 설정을 해준다. 
* 아래는 쉘 파일 내용이니 붙여 넣기한후에 실행 해주면 된다. 

```sh 


function append_hosts_info(){
cat << EOF >> /etc/hosts
# kubernetes nodes
10.0.3.2 k8s-master1
10.0.3.3 k8s-worker1
10.0.3.4 k8s-worker2
EOF


# master 
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --add-masquerade --permanent
firewall-cmd --permanent --add-port=30000-32767/tcp

# worker 
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --add-masquerade --permanent


}


function generate_ssh_key(){

 cat /dev/zero | ssh-keygen -q -N ""

}

function deploy_ssh_key_all_nodes(){

 for i in $(cat /etc/hosts | tail -n 3 | awk '{print $2}') ; do
  ssh-keyscan -t rsa "$i" >> ~/.ssh/known_hosts
  sshpass -p "vagrant" ssh-copy-id -i /root/.ssh/id_rsa.pub root@"$i"
  ssh "$i" hostname
 done


}


main(){

 append_hosts_info
 generate_ssh_key
 deploy_ssh_key_all_nodes

}

main

```

## 설치 하고자 할 cluster 설정 

* kubespray 를 이용하여 cluster를 정의 하려면 inventory 파일을 수정해 주어야 한다. 
* kubespary 의 인벤토리 파일은 inventory 파일의 sample 폴더를 참고 하면 된다. 

```sh 
$ cp -rfp kubespray/inventory/sample kubespray/inventory/mycluster
```


## inventory 설정 

```sh 

$ cat << EOF > kubespray/inventory/mycluster/hosts.ini
[all]
k8s-master ansible_host=10.0.3.2 ip=10.0.3.2 etcd_member_name=etcd1
k8s-node1 ansible_host=10.0.3.3 ip=10.0.3.3
k8s-node2 ansible_host=10.0.3.4 ip=10.0.3.4

[kube-master]
k8s-master

[kube-node]
k8s-master
k8s-node1
k8s-node2

[etcd]
k8s-master

[k8s-cluster:children]
kube-node
kube-master

EOF

$ cat kubespray/inventory/mycluster/hosts.ini

# network 가 flannel -> calico 로 변경해주는 스크립트이다. 
$ sed -i 's/kube_network_plugin: flannel/kube_network_plugin: calico/' kubespray/inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml

# external lb 가 있을경우에는 해당 IP 를 요기 추가해주어야된다. 
$ echo -e "supplementary_addresses_in_ssl_keys: [219.250.188.73]" >> kubespray/inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml

# multus 를 사용할 경우엔 실행 시켜주면 된다. 
$ sed -i 's/kube_network_plugin_multus: false/kube_network_plugin_multus: true/' kubespray/inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
```

## 설치 

* 인벤토리 설정이 정상적으로 진행되었다면 설치를 진행한다. 

```sh 
$ ansible-playbook -b -i inventory/mycluster/host.ini cluster.yml 
```

## 일부 기능만 설치 하고자 할경우 

```sh 
# ansible tag 조회 
ansible-playbook -b -i inventory/mycluster/hosts.ini cluster.yml --list-tags

# 설치하고자 하는 플러그인을 태그명에 넣어준다. 
ansible-playbook -b -i inventory/mycluster/hosts.ini cluster.yml --tags="rbd-provisioner,helm,metrics_server"
ansible-playbook -b -i inventory/mycluster/hosts.ini cluster.yml --tags="ingress_controller"
ansible-playbook -b -i kubespray/inventory/mycluster/hosts.ini kubespray/cluster.yml --tags="coredns,nodelocaldns"
```
