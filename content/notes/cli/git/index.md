---
title: Git commands
weight: 210
menu:
  notes:
    name: git-commands
    identifier: notes-cli-git
    parent: notes-cli
    weight: 10
---

<!-- init -->
{{< note title="init" >}}

```bash
git init 

git config --global user.name "oct28-yjkim@gmail.com" 
git config --global user.email "oct28-yjkim@gamil.com"

git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/oct28-yjkim/test.git
git push -u origin main
```
{{< /note >}}

<!-- add -->
{{< note title="add" >}}

```bash
git add . # current folder 
git add readme.md # readme.md 
```
{{< /note >}}

<!-- commit -->
{{< note title="commit" >}}

```bash
git commit -m "add pelican source"

git log 
commit 4fb60f7260f17fee8cc5b6e4eaf779d8997a2a5a (HEAD -> gh-pages, origin/gh-pages)
Author: yjkim <seaofnight@hanmail.net>
Date:   Sat Sep 14 18:58:04 2019 +0900

    add pelican source
```
{{< /note >}}


<!-- checkout -->
{{< note title="checkout" >}}

```bash
BRANCH_NAME=release-2.16

git checkout $BRANCH_NAME

# clone with specfic branch 
git clone -b $BRANCH_NAME --single-branch  https://github.com/kubernetes-sigs/kubespray.git

```
{{< /note >}}

<!-- push local repo -->
{{< note title="push local repo" >}}

```bash
# init 로 프로젝트 생성 
git init 

# 설정정보 등록 
git config --global user.name "yjkim"
git config --global user.email seaofnight@hanmail.net

# remote 정보 등록, 해당 remote 가 public 사이트이면 프로젝트 생성해야함. e.g github
git remote add origin https://github.com/seaofnight/vitess-example.git

# 병합하기 위하여 pull
git pull origin master

# 업로드 
git push origin master
```
{{< /note >}}

<!-- rebase  -->
{{< note title="rebase" >}}

```bash
# previous 5 commit 
git rebase -i head~5
```
{{< /note >}}
