---
layout: post
title: "安装docker到ECS"
date: 2017-01-11 16:48:04 +0800
comments: true
categories: docker
---

本文不采用阿里云管理平台的配置，安装docker到ECS

<!--more-->

### 准备工作

购买一台阿里ECS，只是为了测试可以使用按量付费并最低配置,系统ubuntu 16.04。注意版本很重要，docker有限支持ubuntu的版本，命名为es-swarm-1

### 安装docker

安装参考[Install Docker on Ubuntu](https://docs.docker.com/engine/installation/linux/ubuntulinux/) (当然也可以通过docker-machine去安装)，本文采用[Install Docker on Ubuntu](https://docs.docker.com/engine/installation/linux/ubuntulinux/)方式。


购买启动后，ssh到购买的ECS上

```
ssh root@xxx.xxx.xxx.xxx
```

更新APT ，确保APT使用https方法，并且已安装CA证书

```
$ sudo apt-get update
$ sudo apt-get install apt-transport-https ca-certificates

```

添加新的GPG密钥

```
$ sudo apt-key adv \
               --keyserver hkp://ha.pool.sks-keyservers.net:80 \
               --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

```

配置docker资源库。“deb https://apt.dockerproject.org/repo ubuntu-xenial main” 部分根据根据不同Ubuntu系统版本使用不同配置

```
$ echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list

```

更新APT 

```
$ sudo apt-get update 

```
在这步会出错，因为阿里将<https://apt.dockerproject.org/repo> 定向到了<http://mirrors.aliyun.com/> 。

解决方法：

* 将 /etc/apt/apt.conf
里 Acquire::http::Proxy "http://mirrors.aliyun.com/"; 注释掉
* 当然也可以配置到阿里的镜像源，速度快还省流量，具体没有实践

配置完成后再次更新APT

```
$ sudo apt-get update 

```
验证下APT是否从正确镜像库拉取

```
$  apt-cache policy docker-engine

 docker-engine:
    Installed: 1.12.2-0~trusty
    Candidate: 1.12.2-0~trusty
    Version table:
   *** 1.12.2-0~trusty 0
          500 https://apt.dockerproject.org/repo/ ubuntu-trusty/main amd64 Packages
          100 /var/lib/dpkg/status
       1.12.1-0~trusty 0
          500 https://apt.dockerproject.org/repo/ ubuntu-trusty/main amd64 Packages
       1.12.0-0~trusty 0
          500 https://apt.dockerproject.org/repo/ ubuntu-trusty/main amd64 Packages

```

对于Ubuntu Trusty，Wily和Xenial，使用aufs存储驱动程序需要安装linux-image-extra- *内核包。

```
$ sudo apt-get update
$ sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual

```

终于可以安装docker了，安装最新版本

```
$ sudo apt-get update
$ sudo apt-get install docker-engine
$ sudo service docker start

```
自己跑一个image测试下，docker安装完成，[后面进行两台ECS实现docker swarm mode](http://www.baidu.com)

* es-swarm-1(manager)
* es-swarm-2(worker)

[ECS docker swarm mode  >>>](http://www.pffair.com/blog/2017/01/11/ecs-docker-swarm/)