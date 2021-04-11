---
layout: post
title: "ecs-docker-swarm"
date: 2017-01-11 21:25:06 +0800
comments: true
categories: docker
---

接前篇[安装docker到ECS](http://www.pffair.com/blog/2017/01/11/docker-on-ecs/)，接下来实现在本机使用docker machine实现swarm创建和节点管理。

* 本机docker machine
* es-swarm-1(manager)
* es-swarm-2(worker)

<!--more-->

### 准备工作
* 为已安装docker的ECS es-swarm-1实例开启端口
	* TCP端口2377用于集群管理通信
	* TCP和UDP端口7946用于节点之间的通信
	* TCP和UDP端口4789用于overlay网络交互
* 对已安装docker的ECS es-swarm-1实例进行自定义镜像制作，阿里的管理控制台一键完成
* 再购买一台ECS实例，采用刚刚制作的自定义镜像，命名为es-swarm-2
* 在本机安装docker machine,我的系统是Mac OS，直接下载dmg安装
* 将本机公钥配置到es-swarm-1、es-swarm-2的authorized_key中，确保本机可以无密登录es-swarm-1、es-swarm-2。可以通过ssh-copy-id方便的配置

```
 ssh-copy-id root@xxx.xxx.xxx.xxx
```

 把xxx.xxx.xxx.xxx分别替换为es-swarm-1、es-swarm-2的ip即可
 

### 关联远程node创建machine实例
通过docker-machine的[generic](https://docs.docker.com/machine/drivers/generic/)实现分别关联远程es-swarm-1、es-swarm-2创建machine实例

```
docker-machine -D create \
--driver generic \
--generic-ip-address xxx.xxx.xxx.xxx \
--generic-ssh-user root es-swarm-1

docker-machine -D create \
--driver generic \
--generic-ip-address xxx.xxx.xxx.xxx \
--generic-ssh-user root es-swarm-2

```
将xxx.xxx.xxx.xxx分别替换为es-swarm-1、es-swarm-2的ip。确认下是否成功

```
 docker-machine ls
```

![](http://www.pffair.com/images/62.png)


### swarm初始化，es-swarm-1做manager

```
eval $(docker-machine env es-swarm-1)

docker swarm init \
  --advertise-addr $(docker-machine ip es-swarm-1)

```

### 将es-swarm-2加入

```
TOKEN=$(docker swarm join-token -q manager)

eval $(docker-machine env es-swarm-2)

docker swarm join \
        --token $TOKEN \
        --advertise-addr $(docker-machine ip es-swarm-2) \
        $(docker-machine ip es-swarm-1):2377
        
```
至此创建完成，查看下节点状态

```
docker node ls

```

![](http://www.pffair.com/images/61.png)


### 为es-swarm-2添加elk label为后续ELK部署做准备

```
docker node update \
        --label-add elk=yes \
        es-swarm-2
```

整个流程我们可以放到一个shell脚本中，一次完成

完整脚本参考[dm-swarm.sh](https://github.com/pangff/docker-swarm-sh/blob/master/scripts/dm-swarm.sh)

[后续，部署ELK，并指定ELK中 elasticsearch部署到指定的es-swarm-2节点 >>>](http://www.pffair.com/blog/2017/01/12/elk-docker/)