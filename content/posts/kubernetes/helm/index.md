---
title: "helm chart 를 이용한 package"
date: 2021-06-08T08:06:25+06:00
description: helm chart 사용법
menu:
  sidebar:
    name: how to use helm chart
    identifier: helm-chart
    parent: Kubernetes
    weight: 20
author:
  name: yjkim
  image: /images/author/john.png
math: true
---

## 개요 

* Kubernetes 의 deployment, statefulset 등의 API 들은 모두 Kubernetes 의 Controller 의 구현체이다.
* 위의 정의되어 있는 형식 외의 다른 형식의 API 를 구성하는것을 CustomResource 라고 하며 K8s 내에는 CustomResourceDefine, CustomResource 를 통하여 API를 정의 하고 정의 한 API 를 사용 하는 방법이 가능하다.
* 이번 블로그 시리즈에서는 KubeBuilder 을 이용하여 CRD 및 CR 을 생성 하여 배포 하는 방법에 대하여 작성 하려 한다.
* Kuberbuilder 는 CRD 를 생성을 편하게 도와주는 boilerplate 프로젝트 이다.

## 순서 

1. 설치
2. sample operator 개발
3. build and push operator

## 설치

* golang version v1.13
* docker version v17.03+
* kubectl v1.11.3+
* kubernetes cluster v1.11.3+
  * 공식 홈에서는 위와같이 나오는데 kustomize 를 내장하여 사용하고 있으며 설치 필요하다.

* golang 설치 
```sh 
{
    wget https://golang.org/dl/go1.15.6.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.15.6.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    go version
}
go version go1.15.6 linux/amd64
```

* docker 설치 
```sh
{
    sudo yum install -y yum-utils
    sudo yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    
    sudo yum install -y docker-ce docker-ce-cli containerd.io wget jq git gcc 
    sudo systemctl enable docker && sudo systemctl start docker 
}
```

* kustomize install 
```sh 
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
install kustomize /usr/local/bin  
```

* kubectl install 
  * 개발하는 서버에서 minikube 로 배포 해도 되고, On premise 로 구축된 서버에 배포 해도 된다. 
```sh 
{
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    kubectl version --client
}
Client Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-13T13:28:09Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
```

* kubebuilder install
```sh 
$ {
    version=2.3.1 # latest stable version
    arch=amd64

    # download the release
    curl -L -O "https://github.com/kubernetes-sigs/kubebuilder/releases/download/v${version}/kubebuilder_${version}_linux_${arch}.tar.gz"

    # extract the archive
    tar -zxvf kubebuilder_${version}_linux_${arch}.tar.gz
    mv kubebuilder_${version}_linux_${arch} kubebuilder && sudo mv kubebuilder /usr/local/

    # update your PATH to include /usr/local/kubebuilder/bin
    export PATH=$PATH:/usr/local/kubebuilder/bin
}
$ kubebuilder --version 
2021/01/20 09:42:48 kubebuilder must be run from the project root under $GOPATH/src/<package>.
Current GOPATH=/root/go.
Current directory=/root/crd
```

여기까지 설치 하면 로컬에서 
  * K8s CRD
  * Operator
  * 쿠베에 배포 하기 위한 client 
까지는 준비 된것이다. 

## create simple project 

* Kubebuilder 로 생성하고자 하는 K8s Project 를 생성 한다. 

```sh 
$ mkdir crd 
$ cd crd
$ go mod init yjkim.io
# go: creating new go.mod: module yjkim.io
```

* K8s CRD 를 정의 한다. 
  * controller runtime builder 을 이용하여 manager, controller golang package 를 생성 해준다. 
  * Workload API Spec 를 정의 하면 해당 workload 에 맞게 Recoile 로직을 작성 하면 된다. 

```sh 
$ kubebuilder init --domain goldilocks.io --license apache2 --owner "nTels.com"
Writing scaffold for you to edit...
Get controller runtime:
go get sigs.k8s.io/controller-runtime@v0.5.0
go: downloading sigs.k8s.io/controller-runtime v0.5.0
go build -o bin/manager main.go
Next: define a resource with:
$ kubebuilder create api
```

* API 정보를 생성 해준다. 
  * OpenAPI v3 으로 생성 해주며 spec 정보는 `/api` 폴더를 참고 하면 된다. 
  * 물론 app 형상에 맞게 변경 해주어야 한다. 

```sh 
$ kubebuilder create api --group group --version v1 --kind Group
Create Resource [y/n]
y
Create Controller [y/n]
y

Writing scaffold for you to edit...
api/v1/group_types.go
controllers/group_controller.go
Running make:
$ make
which: no controller-gen in (/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/go/bin:/usr/local/go/bin:/root/bin:/usr/local/bin:/usr/local/kubebuilder/bin:/root/bin:/usr/local/bin:/usr/local/go/bin:/root/bin:/usr/local/bin:/usr/local/go/bin:/usr/local/kubebuilder/bin:/usr/local/kubebuilder/bin)
go: creating new go.mod: module tmp
go: found sigs.k8s.io/controller-tools/cmd/controller-gen in sigs.k8s.io/controller-tools v0.2.5
/root/go/bin/controller-gen object:headerFile="hack/boilerplate.go.txt" paths="./..."
go fmt ./...
go vet ./...
go build -o bin/manager main.go

# api 에서 y 를 선택 하면 아래 groups_type.go 가 생성 된다. 
$ ls -al api/v1/
group_types.go            groupversion_info.go      zz_generated.deepcopy.go

# api 생성시에 controller 생성 프롬프트에서 y 를 선택하면 아래 group_controller.go 파일이 생성된다. 
$ ls -al controllers/
group_controller.go  suite_test.go
```

* 생성한 CRD 를 K8s 에 배포 해본다. 
* 아무런 변화는 없을 것이며 K8s 에서 API 적으로 배포 된 형상만 출력 될 것이다. 

```sh 
# 만든 controller 을 실행 한다. 
$ make install && make run 

# ctrl + c 로 종료 

# 클러스터에 설치된 customresource 를 삭제한다. 
$ make 
```

## 나만의 CustomResource 생성하기 

이제 CRD 를 생성 하고 K8s 에 CRD, CR 까지 배포 해보았다. 

* 생성한 Project 구성을 보자

```sh 
$ tree -d .
.
├── api
│   └── v1
├── bin
├── config
│   ├── certmanager
│   ├── crd
│   │   ├── bases
│   │   └── patches
│   ├── default
│   ├── manager
│   ├── prometheus
│   ├── rbac
│   ├── samples
│   └── webhook
├── controllers
├── crd
│   ├── config
│   │   ├── certmanager
│   │   ├── default
│   │   ├── manager
│   │   ├── prometheus
│   │   ├── rbac
│   │   └── webhook
│   └── hack
└── hack
```

## Packages 

### API ? 

kubebuilder create api 명령어를 이용하여 생성을 하면 리소스를 생성 하겠느냐? 라고 물어보는데 y 를 입력하면 api/{입력한 버전:=v1|v1beta|v1alpha}/{입력한 그룹명}_types.go 으로 API 리소스를 생성 해준다.

```sh 
$ ls -al api/v1/
total 12
drwx------. 2 root root   88  1월 20 10:14 .
drwx------. 3 root root   16  1월 20 10:14 ..
-rw-------. 1 root root 1890  1월 20 10:14 group_types.go
-rw-------. 1 root root 1218  1월 20 10:14 groupversion_info.go
-rw-r--r--. 1 root root 3165  1월 20 10:19 zz_generated.deepcopy.go
```


* groupversion_info.go 파일은 API 리소스의 버전 정보의 구조체 이다. 수정하지는 않는다.
* zz_generated.deepcopy.go 파일은 Controller 로 생성된 객체정보를 CRD에 반영해주는 파일이다. 수정 하지는 않는다.
* `*_types.go` 파일이 우리가 Controller 로 API 의 정보를 전달할 model 클래스 라고 보면 된다.
   * API 에서 여러개의 API리소스를 구성하는 경우도 있지만 Kubebuilder 에서는 여러 Model 을 1개의 *_type.go 파일에 집어 넣지 말라고 이야기 하고 있다.
   * 아래 예시 처럼 Spec 파일에 CRD 에 들어가는 json 정의를 작성 하면 config/sample/*.yaml 에 있는 예시파일에 맞추어서 CR 을 배포 하면 된다.

```sh 
# golang /api/v1/group_types.go
// GroupSpec defines the desired state of Group
type GroupSpec struct {
        // INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
        // Important: Run "make" to regenerate code after modifying this file

        // Foo is an example field of Group. Edit Group_types.go to remove/update
        Foo string `json:"foo,omitempty"`
```


### Manager ? 

* Manager 패키지는 프로젝트의 root 에 있는 main.go 파일이다.
   * metrics, log, leader 설정을 할 수 있으며
   * 빌드 시에는 /bin 에 manager 로 생성되며 Dockerfile 로 이미지 생성까지 자동화 되어있다.

### Controller ? 

* Controller 는 CR 이 생성될 K8s Native 객체들(e.g pod, deployment, configmap)을 조정이라는 메서드를 통하여 지속적으로 상태를 기대상태로 유지하도록 해주는 코어 패키지이다.
* kubebuilder create api 명령에서 리소스를 생성하겠느냐는 물음에 y를 입력하면 아래 컨트롤러 파일이 생성 된다.
   * 생성한 API이름이 group 여서 group_cluster.go로 생성이 되었다.
   * 아래 집중해야할 항목이 Reconcile 메서드와 SetupWithManager 함수이다.
* SetupWithManager 는 Manager 가 시작시에 Controller 을 등록 하는 함수이다.
   * 해당 함수 내에서 소유할 객체와 감시할 대상을 정의 할 수 있다.
   * 여러개의 Operator 이 들어가서 1개의 K8s 클러스터에 CR을 병행 배포하려 한다면 Index 를 하여서 선별적으로 감시 할 수 있다.
* Recoile 함수는 조정 함수로 kuberntes 의 corev1, appv1 API 를 이용하여 K8s Native 객체를 생성 조정 한다.
* local cache 를 설정할 수 있으나 테스트 안해보았다.

```sh
#/project_root
tree .
├── controllers
│   ├── group_controller.go

$ cat controllers/group_controller.go
/*
lice info text 
...
*/
package controllers

import (
        "context"

        "github.com/go-logr/logr"
        "k8s.io/apimachinery/pkg/runtime"
        ctrl "sigs.k8s.io/controller-runtime"
        "sigs.k8s.io/controller-runtime/pkg/client"

        groupv1 "yjkim.io/api/v1"
)

// GroupReconciler reconciles a Group object
type GroupReconciler struct {
        client.Client
        Log    logr.Logger
        Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=group.goldilocks.io,resources=groups,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=group.goldilocks.io,resources=groups/status,verbs=get;update;patch

func (r *GroupReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
        _ = context.Background()
        _ = r.Log.WithValues("group", req.NamespacedName)

        // your logic here

        return ctrl.Result{}, nil
}

func (r *GroupReconciler) SetupWithManager(mgr ctrl.Manager) error {
        return ctrl.NewControllerManagedBy(mgr).
                For(&groupv1.Group{}).
                Complete(r)
}
```

* kubebuilder 는 controller-gen 을 이용하여 객체를 생성 하는데 RBAC 객체를 생성하고자 한다면 marker 을 사용해야 한다.
   * marker 는 아래와 같은 형식이며 작성하면 /config/rbac 에 RBAC manifest 를 생성해준다.
   * rbac 는 당연히 make install 시에 설치 된다.

```sh 
// marker 예시 

// +kubebuilder:rbac:groups=group.goldilocks.io,resources=groups,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=group.goldilocks.io,resources=groups/status,verbs=get;update;patch
```

## simple example 

* 예시로 위에 있는 정보를 가지고 2개의 Pod를 생성후 조정하는 예제를 작성하고자 한다.
   * 예시에는 생성 객체를 index, local cache, manager ha 등의 예제는 없다.
* vscode 의 lang linter 혹은 문법 체크가 되는 환경에서 실행하는걸 추천한다. 

```sh 
# project 생성 및 api 생성 
$ go mod init yjkim.io
$ kubebuilder init --domain goldilocks.io --license apache2 --owner "nTels.com"
$ kubebuilder create api --group group --version v1 --kind Group
Create Resource [y/n]
y
Create Controller [y/n]
y
```

```sh 
// api/v1/group_type.go
// GroupSpec defines the desired state of Group
type GroupSpec struct {
        Replicas int `json:"replicas,omitempty"` //FOO -> replicas
}
```

```sh 
//controllers/group_controller.go
// +kubebuilder:rbac:groups=group.goldilocks.io,resources=groups,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=group.goldilocks.io,resources=groups/status,verbs=get;update;patch

func (r *GroupReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	_ = context.Background()
	log := r.Log.WithValues("req.Namespace", req.Namespace, "req.Name", req.Name)

	log.Info("Reconciling simple CRD Clusters.")

	group := &groupv1.Group{}

	if err := r.Get(context.TODO(), req.NamespacedName, group); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	var replicas = group.Spec.Replicas

	for i := 1; i <= replicas; i++ {
		member := &corev1.Pod{
			ObjectMeta: metav1.ObjectMeta{
				Name:      "g" + strconv.Itoa(i),
				Namespace: group.Namespace,
				Labels: map[string]string{
					"app": "g" + strconv.Itoa(i),
				},
			},
			Spec: corev1.PodSpec{
				Containers: []corev1.Container{
					{
						Name:  "g" + strconv.Itoa(i),
						Image: "nginx",
					},
				},
				RestartPolicy: corev1.RestartPolicyOnFailure,
			},
		}
		err := r.Client.Get(context.TODO(), types.NamespacedName{Name: group.Name, Namespace: group.Namespace}, &corev1.Pod{})

		if err != nil && errors.IsNotFound(err) {
			err = r.Client.Create(context.TODO(), member)

			if err != nil {
				log.Error(err, "Failed to create new Member.", "Namespace", group.Namespace, "Name", group)
			}
		}

	}

	return ctrl.Result{}, nil
}

func (r *GroupReconciler) getEnqueObjects(obj handler.MapObject) []ctrl.Request {
	listOptions := []client.ListOption{
		client.InNamespace(obj.Meta.GetNamespace()),
	}

	var list groupv1.GroupList
	if err := r.Client.List(context.Background(), &list, listOptions...); err != nil {
		log.Error("getEnqueObjects: ", err)
		return nil
	}

	res := make([]ctrl.Request, len(list.Items))
	for i, watchlist := range list.Items {
		res[i].Name = watchlist.Name
		res[i].Namespace = watchlist.Namespace
	}
	return res
}

func (r *GroupReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&groupv1.Group{}).
		Watches(
			&source.Kind{Type: &corev1.Pod{}},
			&handler.EnqueueRequestsFromMapFunc{
				ToRequests: handler.ToRequestsFunc(r.getEnqueObjects)}).
		Complete(r)
}

```



* Recoile 함수는 CR 을 생성 후에 하위 객체들을 조정 하는 함수 이며
   * // +kubebuilder:rbac 문구는 Kubebuilder 에서 marker 로 RBAC 객체를 생성 해주는 라인이다.
   * if err := r.Get(context.TODO(), req.NamespacedName, group); Client 를 이용하여 Cluster 에 CR 이 배포 되었는지 확인하는 소스이다.
   * member := &corev1.Pod{ k8s corev1 API 를 이용하여 Pod Manifest 를 정의 하는 소스 이다.
   * err := r.Client.Get(context.TODO(), types.NamespacedName{ Pod Manifest 를 Cluster 에 조회 하는 소스 이다.
   * err = r.Client.Create(context.TODO(), member) Pod 를 클러스터에 생성 하는 소스 이다.

* SetupWithManager 함수는 현재 이 &groupv1.Group{} Controller 을 Manager 에 등록 하는 소스 이다.
   * Recoile 함수가 발동 될 대상을 정의 하는 함수 이다.
   * ToRequests: handler.ToRequestsFunc(r.getEnqueObjects)}). Cluster 에 있는 Group CRD 를 Client를 이용하여 조회 하여 Recoile 발생 하도록 요청 하는 소스이다.

* getEnqueObjects 함수는 Watches 함수 내에서 사용하는 함수 이다.
   * Client 를 이용하여 CR 를 조회 하여 등록 하는 함수 이다.

* 생성한 Operator 을 Cluster 에 배포, local 에서 실행 한다.

```sh 
# make generate : bin 에 파일이 생성됨 
# make install : CRD 를 Kube cluster 에 설치 함
$ make generate && make install 

# local 에서 manager 파일을 실행 
$ make run 

```

* sample manifest 를 수정 한다.
   * 이미 config/sample 안에 한개의 Manifest 가 생성이 되어 있다.
   * *_types.go 파일의 형식에 맞게 수정 해준다.

```sh 
apiVersion: group.goldilocks.io/v1
kind: Group
metadata:
  name: group-sample
spec:
  # Add fields here
  # foo: bar -> replicas:2
  replicas: 2

```

* 수정한 CR 을 K8s Cluster 에 배포 한다.

```sh 
$ kubectl create -f config/sample 
group.group.goldilocks.io/group-sample created

$ kubectl get po 
NAME   READY   STATUS    RESTARTS   AGE
g1     1/1     Running   0          40s
g2     1/1     Running   0          40s

$ kubectl get groups
NAME           AGE
group-sample   45s
```

* 생성한 Pod를 수동으로 삭제 해도 Recoile 로직이 잘 발동 하여서 다시 생성을 해준다.

```sh 
$ kubectl get po 
NAME   READY   STATUS    RESTARTS   AGE
g1     1/1     Running   0          115s
g2     1/1     Running   0          115s

$ kubectl delete po g2 
pod "g2" deleted

$ kubectl get po 
NAME   READY   STATUS              RESTARTS   AGE
g1     1/1     Running             0          2m13s
g2     0/1     ContainerCreating   0          5s

```