---
title: Filewalld commands
weight: 210
menu:
  notes:
    name: firewalld-commands
    identifier: notes-cli-firewalld
    parent: notes-cli
    weight: 10
---

<!-- Install -->
{{< note title="Install" >}}

```bash
$ sudo yum install -y firewalld 
$ sudo systemctl status firewalld 
$ sudo systemctl start firewalld 
$ sudo firewall-cmd --state
```

{{< /note >}}

<!-- Select Zone -->
{{< note title="Select Zone" >}}

```bash
# Default 조회 
$ sudo firewall-cmd --get-default-zone

# Active Zone list 조회 
$ firewall-cmd --get-active-zones

# 특정 Zone 의 정보 조회 
$ sudo firewall-cmd --zone=home --list-all
```

{{< /note >}}

<!-- Change Default Zone -->
{{< note title="Change Default Zone" >}}

```bash
sudo firewall-cmd --set-default-zone=home
```

{{< /note >}}

<!-- Accept Service to Specfic Zone -->
{{< note title="Accept Service to Specfic Zone" >}}

* Zone 에 Service 허용 
   * 영구`--permanent`와 비영구의 차이는 `--reload` 시에 비영구 옵션은 사라진다. 

```bash
# Http 서비스 허용 
$ sudo firewall-cmd --zone=public --add-service=http
$ sudo firewall-cmd --zone=public --list-services
output : dhcpv6-client http ssh

# Http 서비스 영구 허용 
$ sudo firewall-cmd --zone=public --permanent --add-service=http

# Port/protocol 로 허용 
$ sudo firewall-cmd --zone=public --add-port=5000/tcp
$ sudo firewall-cmd --zone=public --list-ports
output : 5000/tcp

# Port/protocol 로 영구 허용 
$ sudo firewall-cmd --zone=public --add-port=5000/tcp
```

{{< /note >}}

<!-- Firewalld Service restart  -->
{{< note title="Firewalld Service restart " >}}

```bash
sudo firewall-cmd --reload
```

{{< /note >}}

<!-- Add Port Example  -->
{{< note title="Add Port Example" >}}

```bash
{
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --add-masquerade --permanent

systemctl restart firewalld
}

{
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp

systemctl restart firewalld
}
```

{{< /note >}}
