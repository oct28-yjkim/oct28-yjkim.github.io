---
title: "helm chart 를 이용한 package"
date: 2021-06-08T08:06:25+06:00
description: helm chart 사용법
menu:
  sidebar:
    name: helm chart
    identifier: helm-chart
    parent: Kubernetes
    weight: 20
author:
  name: yjkim
  image: /images/author/john.png
math: true
---

## Helm Project 소개 

Helm 이란 Kubernetes Manafest 의 버전관리 및 Packageing 를 도와주는 Opensource Project 이다. 
만약 App이 개발이 되었을 시에는 단순 1개의 Manifest 가 아니라 Deployment, Configmap, Secret 등등 기타 관리 되어야 할 파일들이 늘어날 것이다. 
해당 파일들은 버전이 올라가게 되면서 다른 변경점을 가진 파일들이 늘어 날 것이고 프로젝트가 복잡해지면서 관리 하기는 어려워 질 것이다. 
그리하여 Helm Project 에서는 `Chart` 라는 Manifest 를 관리하기 위한 Group 개념을 지원한다. 
Chart 를 배포하기 위한 Helm `Repo` 구성도 가능하다. 일반적인 Http, nginx 웹 서버 혹은 github 를 사용한다면 쉽게 이용이 가능하다. 
helm Chart 로 배포 한 Package 는 `Release` 로 불린다. 

## Helm cli 설치

설치는 helm cli 를 다운 받으면 끝난다.
helm cli를 통하여 chart 를 배포 요청 하면 helm cli 에서 kubernetes manifest 로 변환을 해주고 배포 해준다. 
배포시에는 기본 KUBECONFIG 환경변수 인 ~/.kube/config 정보를 참조 하여 배포 요청 한다. 

```sh 
## 방법 1
# release 다운로드 페이지에서 다운 받기
https github com helm helm releases
## 방법 2
# window package mgmt 사용 cholatey
choco install kubernetes helm
## 방법 3
# linux snap store 에서 다운
sudo snap install helm classic
## 방법 4
# script 로 다운 받기
curl https raw githubusercontent com helm helm master scripts get helm 3 | bash
```

## helm cli 를 이용한 chart 사용법 

#### helm search command 

```sh 
# helm search hub : https://hub.helm.sh/ 에서 검색
[root@di7-03 ~]# helm search hub gitlab
URL                                               	CHART VERSION   	APP VERSION     	DESCRIPTION                                       
https://hub.helm.sh/charts/choerodon/gitlab-ser...	0.21.0          	0.21.0          	gitlab-service for Choerodon                      
https://hub.helm.sh/charts/choerodon/gitlab       	0.5.4           	0.5.4           	gitlab for Choerodon                              
https://hub.helm.sh/charts/choerodon/gitlab-runner	0.2.4           	0.2.4           	gitlab-runner for Choerodon             

# helm search repo : local 에 등록된 repo 에서 검색 
[root@di7-03 ~]# helm search repo gitlab
NAME                         	CHART VERSION	APP VERSION	DESCRIPTION                                       
gitlab/gitlab                	3.1.4        	12.8.6     	Web-based Git-repository manager with wiki and ...
gitlab/gitlab-omnibus        	0.1.37       	           	GitLab Omnibus all-in-one bundle                  
gitlab/gitlab-runner         	0.14.0       	12.8.0     	GitLab Runner                                     
```

#### helm install command 

```sh 
[root@di7-03 ~]# helm install chf-maria stable/mariadb --namespace default
WARNING: This chart is deprecated
NAME: chf-maria
LAST DEPLOYED: Wed Apr  1 23:35:02 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
[root@di7-03 ~]# helm list
NAME     	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
chf-maria	default  	1       	2020-04-01 23:35:02.149481848 +0900 KST	deployed	mariadb-7.3.13	10.3.22    

# helm fetch 후 install 

# helm unpacked chart install 

# public 망에서 url 기반 install 
```

* values override 
  * `helm show values` 명령어로 chart values.yaml 값 조회 
  * `--set` 혹은 `--values, -f` arg 로 override 하기 

```sh 
helm show values stable/mariadb

echo '{mariadbUser: user0, mariadbDatabase: user0db}' > config.yaml
helm install -f config.yaml stable/mariadb --generate-name
```



#### helm status command 

```sh 
# helm notice 출력 
[root@di7-03 ~]# helm status chf-maria
NAME: chf-maria
LAST DEPLOYED: Wed Apr  1 23:35:02 2020
NAMESPACE: default
STATUS: deployed
```

#### helm upgrade command 

```sh 
# update 
[root@di7-03 helm]# helm list
NAME	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
abc 	default  	1       	2020-04-01 23:41:38.996393571 +0900 KST	deployed	mariadb-7.3.13	10.3.22    

[root@di7-03 helm]# echo '{mariadbUser: user0, mariadbDatabase: user0db}' > config.yaml

[root@di7-03 helm]# helm upgrade -f config.yaml abc stable/mariadb
WARNING: This chart is deprecated
Release "abc" has been upgraded. Happy Helming!
NAME: abc
LAST DEPLOYED: Wed Apr  1 23:43:15 2020
NAMESPACE: default
STATUS: deployed
REVISION: 2
NOTES:
This Helm chart is deprecated

[root@di7-03 helm]# helm get values abc
USER-SUPPLIED VALUES:
mariadbDatabase: user0db
mariadbUser: user0

[root@di7-03 helm]# helm list
NAME	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
abc 	default  	2       	2020-04-01 23:43:15.567604711 +0900 KST	deployed	mariadb-7.3.13	10.3.22    
```

#### helm rollback command 

```sh
[root@di7-03 helm]# helm list
NAME	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
abc 	default  	2       	2020-04-01 23:43:15.567604711 +0900 KST	deployed	mariadb-7.3.13	10.3.22    
[root@di7-03 helm]# helm get values abc
USER-SUPPLIED VALUES:
mariadbDatabase: user0db
mariadbUser: user0

[root@di7-03 helm]# helm ls
NAME	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
abc 	default  	3       	2020-04-01 23:46:51.761668024 +0900 KST	deployed	mariadb-7.3.13	10.3.22    

[root@di7-03 helm]# helm get values abc
USER-SUPPLIED VALUES:
null

[root@di7-03 helm]# helm history abc
REVISION	UPDATED                 	STATUS    	CHART         	APP VERSION	DESCRIPTION     
1       	Wed Apr  1 23:41:38 2020	superseded	mariadb-7.3.13	10.3.22    	Install complete
2       	Wed Apr  1 23:43:15 2020	superseded	mariadb-7.3.13	10.3.22    	Upgrade complete
3       	Wed Apr  1 23:46:51 2020	deployed  	mariadb-7.3.13	10.3.22    	Rollback to 1   
```

* --timeout
* --wait
* --no-hooks
* --recreate-pods

#### helm uninstall command 

```sh
[root@di7-03 helm]# helm uninstall abc
release "abc" uninstalled

[root@di7-03 helm]# helm uninstall abc --keep-history
release "abc" uninstalled
[root@di7-03 helm]# helm list
NAME	NAMESPACE	REVISION	UPDATED	STATUS	CHART	APP VERSION
[root@di7-03 helm]# helm list --uninstalled
NAME	NAMESPACE	REVISION	UPDATED                                	STATUS     	CHART         	APP VERSION
abc 	default  	2       	2020-04-01 23:50:04.259693547 +0900 KST	uninstalled	mariadb-7.3.13	10.3.22    
```

## helm chi 를 이용한 repo 명령어


```sh 

[root@di7-03 helm]# helm repo list
NAME  	URL                                              
stable	https://kubernetes-charts.storage.googleapis.com/

[root@di7-03 helm]# helm repo remove stable
"stable" has been removed from your repositories

[root@di7-03 helm]# helm repo list                     
NAME  	URL                                              
stable	https://kubernetes-charts.storage.googleapis.com/
gitlab	https://charts.gitlab.io/                        
loki  	https://grafana.github.io/loki/charts  

[root@di7-03 helm]# helm repo add stable https://kubernetes-charts.storage.googleapis.com/
"stable" has been added to your repositories
[root@di7-03 helm]# helm repo list
NAME  	URL                                              
gitlab	https://charts.gitlab.io/                        
loki  	https://grafana.github.io/loki/charts            
stable	https://kubernetes-charts.storage.googleapis.com/
```

## helm chart 의 구조 

* create chart command 를 이용하여 임의의 test chart 를 생성 해본다. 

```sh 
[root@di7-03 helm]# helm create my-chart
Creating my-chart
[root@di7-03 helm]# cd my-chart/
[root@di7-03 my-chart]# tree .
.
├── Chart.yaml
├── charts
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── ingress.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml

3 directories, 9 files

[root@di7-03 helm]# helm package my-chart
Successfully packaged chart and saved it to: /root/yjkim/helm/my-chart-0.1.0.tgz
```

#### chart 배포 디버깅 

* chart 를 설치 하기전에 `--debug` 와 `--dry-run` 구문을 사용할 수 있습니다. 
* `--debug` 구문은 chart -> kube manifest 로 변환시에 spec yaml 을 출력 해줍니다. 이 구문을 실행하면 배포도 됩니다. 
* `--dry-run` 구문은 manifest 의 yaml spec 을  출력 해줍니다. 배포 하지 않습니다. 

```sh 
# debug example 
[root@di7-03 my-chart]# helm install test . -f values.yaml --debug

# dryrun example 
[root@di7-03 my-chart]# helm install test . -f values.yaml --dry-run
```


#### chart name 

* chart 명은 소문자 및 숫자만 사용 가능합니다. 각 문자는 dash - 로 구분할 수 있습니다. 
* chart 명에 대문자 및 언더스코어 `_` 닷 `.` 는 사용할 수 없습니다. 

```yaml 
# 가능 
drupal
nginx-lego
aws-cluster-autoscaler
```

#### values.yaml 

* values.yaml 파일은 정의된 chart 에 값을 변경하여 배포자가 원하는 형상으로 배포할 수 있도록 변경할 수 있도록 override 기능을 제공해줍니다. 

* values 의 data type 는 [링크](https://helm.sh/docs/chart_template_guide/data_types/) 를 참조 바랍니다.

```yaml 
# example 
chicken: true
chickenNoodleSoup: true

# 잘못된경우 
Chicken: true  # 내부 함수와 충돌 날 수 있음 
chicken-noodle-soup: true # 하이픈(-) 을 사용하지 않습니다. 

## 표현예시 
# nasted 
server:
  name: nginx
  port: 80

# Flat 
serverName: nginx
serverPort: 80
```
```sh
## 표현예시 
[root@di7-03 my-chart]# diff values.yaml nasted.yaml 
35,37c35,39
< service:
<   type: ClusterIP
<   port: 80
---
> #service:
> #  type: ClusterIP
> #  port: 80
> serviceType: clusterIP
> servicePort: 8080

[root@di7-03 my-chart]# helm install test . -f nasted.yaml --dry-run

NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=my-chart,app.kubernetes.io/instance=test" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:80
```

#### templates

* helm chart 를 구성하고 kube manifest 를 정의 하기 위하여는 helm template 의 양식대로 chart 를 작성 하여야 합니다. 

```sh 
# chart create 
[root@di7-03 helm]# helm create mytest
Creating mytest
[root@di7-03 helm]# tree mytest
mytest
├── Chart.yaml
├── charts
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── ingress.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml

3 directories, 9 files
```

* `/templates` 폴더는 helm chart 의 양식 파일로 kube manifest 가 정의 되어있습니다. 
  * 배포를 요청하면 helm 의 template engin에서 kube manifest 를 렌더링 한 후에 kube 서버로 전송하게 될 양식들 입니다. 
* `NOTES.txt` chart 가 deploy 된 후에 사용자에게 출력 될 문자열 입니다. 
* `deployment.yaml` kubernetes 의 deployment manifest 입니다. 
* `_helpers.tpl` chart 의 template 간의 재 사용될 수 있는 양식 객체 입니다. 
* Chart 는 [go template engine](https://godoc.org/text/template) 와 [Sqrig 라이브러리](https://masterminds.github.io/sprig/)의 내장 기능을 제공 합니다. 


```sh 
# template 생성 예제 
[root@di7-03 mytest]# vi templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychart-configmap
data:
  myvalue: "Hello World"

[root@di7-03 mytest]# helm install test .
NAME: test
LAST DEPLOYED: Thu Apr  2 01:38:51 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=mytest,app.kubernetes.io/instance=test" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:80

[root@di7-03 mytest]# k get cm -o yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    myvalue: Hello World
  kind: ConfigMap
  metadata:
    creationTimestamp: "2020-04-01T16:38:51Z"
    name: mychart-configmap
    namespace: default
    resourceVersion: "8687183"
    selfLink: /api/v1/namespaces/default/configmaps/mychart-configmap
    uid: cb509e8b-05a5-47c3-9716-bbb6816855f8
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""

[root@di7-03 mytest]# helm get manifest test
---
# Source: mytest/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychart-configmap
data:
  myvalue: "Hello World"
```

```sh 
# template 적용 예제 
[root@di7-03 mytest]# cat templates/configmap.yaml 
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"

[root@di7-03 mytest]# helm install test .
NAME: test
LAST DEPLOYED: Thu Apr  2 01:42:20 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=mytest,app.kubernetes.io/instance=test" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:80
[root@di7-03 mytest]# helm get manifest 
Error: "helm get manifest" requires 1 argument

Usage:  helm get manifest RELEASE_NAME [flags]
[root@di7-03 mytest]# helm get manifest  test
---
# Source: mytest/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: test-configmap
data:
  myvalue: "Hello World"

[root@di7-03 mytest]# k get cm -o yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    myvalue: Hello World
  kind: ConfigMap
  metadata:
    creationTimestamp: "2020-04-01T16:42:20Z"
    name: test-configmap
    namespace: default
    resourceVersion: "8687966"
    selfLink: /api/v1/namespaces/default/configmaps/test-configmap
    uid: 06b82abe-c350-431b-83aa-2586cd35aadf
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

* values 파일을 통한 template function 적용은 [공홈 참조](https://helm.sh/docs/chart_template_guide/values_files/)



#### chart hook  

* helm chart 는 hook 를 기본 내장 하고 있으며 그 중에 한가지 테스트를 해본다. 
* chart template 에 annotation 을 등록 하면 hook 를 이용할 수 있다. 

```sh 
[root@di7-03 my-chart]# cat templates/pre-install.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: pre-install-hook-pod
  annotations:
    "helm.sh/hook": "pre-install"
spec:
  containers:
  - name: hook1-container
    image: busybox
    imagePullPolicy: IfNotPresent
    command: ['sh', '-c', 'echo The pre-install hook Pod is running && sleep 10']
  restartPolicy: Never
  terminationGracePeriodSeconds: 0

[root@di7-03 my-chart]# cat templates/post-install.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: post-install-hook-pod
  annotations:
    "helm.sh/hook": "post-install"
spec:
  containers:
  - name: hook1-container
    image: busybox
    imagePullPolicy: IfNotPresent
    command: ['sh', '-c', 'echo post-install hook Pod is running && sleep 10']
  restartPolicy: Never
  terminationGracePeriodSeconds: 0

[root@di7-03 my-chart]# helm install my-test .
Pod pre-install-hook-pod pending
Pod pre-install-hook-pod pending
Pod pre-install-hook-pod pending
Pod pre-install-hook-pod running
Pod pre-install-hook-pod succeeded
Pod post-install-hook-pod pending
Pod post-install-hook-pod pending
Pod post-install-hook-pod pending
Pod post-install-hook-pod running
Pod post-install-hook-pod succeeded
NAME: my-test
LAST DEPLOYED: Thu Apr  2 01:25:48 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=my-chart,app.kubernetes.io/instance=my-test" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace default port-forward $POD_NAME 8080:80

[root@di7-03 my-chart]# helm list
NAME   	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
my-test	default  	1       	2020-04-02 01:25:48.299571978 +0900 KST	deployed	my-chart-0.1.0	1.16.0    

[root@di7-03 my-chart]# kubectl get po
NAME                    READY   STATUS      RESTARTS   AGE
post-install-hook-pod   0/1     Completed   0          71s
pre-install-hook-pod    0/1     Completed   0          83s

```

* [참고자료](https://helm.sh/docs/topics/charts_hooks/)