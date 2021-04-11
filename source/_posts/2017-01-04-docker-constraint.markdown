---
layout: post
title: "docker-constraint"
date: 2017-01-04 12:59:55 +0800
comments: true
categories: docker
---
在docker swarm mode中create service到指定label的node下。

以下操作前提是已经创建好了swarm mode的两个node: swarm-1（manager）、swarm-2(worker)。

<!--more-->

#### 通过node update为swarm-2添加label elk=yes

```
docker node update \
        --label-add elk=yes \
        swarm-2
```

#### 通过在docker service create中指定--constraint 限制service只能运行到node.labels.elk==yes的节点（就是前面指定的swarm-2节点）

```
docker service create \
		-p 3000:3000 \
		--name hello-service \
		--mode=global \
		--constraint 'node.labels.elk==yes' \
		marshalw/hello-service:0.2.2
```

#### 使用docker service ps查看service情况

```
 docker service ps hello-service
```

![](http://www.pffair.com/images/58.png)

根据上面的图可以看到hello-service只运行到了swarm-2上。


### 测试当节点mount不存在volumn时候是否能正常创建service

```
docker service rm hello-service

docker service create \
		-p 3000:3000 \
		--name hello-service \
		--mode=global \
		--constraint 'node.labels.elk==yes' \
		--mount 'type=bind,source=$PWD,target=/var/lib/hello' \
		marshalw/hello-service:0.2.2
```
查看测试结果

```
 docker service ps hello-service
```

![](http://www.pffair.com/images/59.png)

说明可以正常创建，但是不能启动，对于非指定label的节点没有影响