---
layout: post
title: "logspout-redis-elk"
date: 2017-01-20 13:56:16 +0800
comments: true
categories: docker
---

接上篇[logspout-elk](http://www.pffair.com/blog/2017/01/15/logspout-elk/).我们在上篇中完成了使用logspout收集docker日志并发送到logstash中。本文在之前的基础上在logspout到logstash之间添加了redis消息队列。

<!--more-->

### 为什么要添加消息队列呢？

参考ELK官方的文档[Managing Throughput Spikes with Message Queueing](https://www.elastic.co/guide/en/logstash/current/deploying-and-scaling.html#deploying-message-queueing)。当logstash索引消费速率低于传入速率时Logstash将会对传入事件进行限制，这样会使传入事件在数据源头堆积。添加消息队列不仅可以起到防止back pressure作用同时还可以放置数据丢失。当从消息队列消费数据失败我们还可以重新获取。在我们之前的架构中如果事件消费出现异常(比如我们的Elasticsearch出现问题)不能及时消费logstash获取到的日志时那么logstash做限入控制，数据将会在我们的container堆积，而此时如果我们container出现问题而被remove并且恰恰没有mount宿主机磁盘进行log存储的话那么我们之前的日志将会全部丢失，由此可见添加消息队列的重要性。至于为什么选用redis，只是简单了解到它的速度、易用性、和低资源需求比较好，最主要的原因还是相对 Kafka、RabbitMQ对它更熟悉。如果感兴趣可以对（redis、kafka、RabbitMQ）做一个简单对比和测试

### 添加redis message broker

由于采用redis message broker我们需要修改logstash的配置文件，所以整体的service创建我们重新走一遍，也算对之前内容的巩固

开始之前将全部的service、network删除

**删除service**

```
docker service rm logstash \
elasticsearch proxy \
swarm-listener kibana

```

**删除network**

```
docker network rm elk proxy

```

**创建elk overlay network**

```
docker network create --driver overlay elk

```

**创建elasticsearch service**

```
docker service create --name elasticsearch \
    --mode global \
    --network elk \
    -p 9200:9200 \
    -e ES_JAVA_OPTS="-Dmapper.allow_dots_in_name=true" \
    --constraint "node.labels.elk == yes" \
    --reserve-memory 500m \
    elasticsearch:2.4

```
需要注意的是

```
-e ES_JAVA_OPTS="-Dmapper.allow_dots_in_name=true"
```
这个环境变量，使用它的目的是为了让Elasticsearch允许日志属性名称中有"."，比如类似com.docker.node.id这样的属性名字，在Elasticsearch 2.X版本中是不允许的收集的日志中如果存在的话Elasticsearch会抛异常

```
MapperParsingException[Field name [com.docker.node.id] cannot contain '.'] 
```

*加个小备注：Elasticsearch的日志可以通过。* **docker ps -a**
*找到Elasticsearch的container id然后*
**docker logs containerid** *查看*

具体关于点的问题可以参考[dots-in-names](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/dots-in-names.html)
当然也可以直接安装5.X的[Elasticsearch](https://hub.docker.com/_/elasticsearch/)，5.0默认是支持的。我开始尝试安装5.0版本但是create service 会提示netwrok not found，不能创建成功，之后没有再尝试解决，感兴趣的话可以试试并且将elasticsearch 2.X版本和5.X做一个比较，5.x相对2.x的变化

**创建redis service,加入到elk network**

```
docker service create --name redis \
--network elk \
-p 6379:6379  redis redis-server --requirepass redis

```
通过redis-server --requirepass 设置密码为redis。建议这里要设置密码，再实际操作时发现外部全局扫描redis时候并且可能运行CONFIG SET REQUIREPASS，会锁定redis运行实例，出现授权提示[参考](http://stackoverflow.com/questions/34115213/redis-raise-error-noauth-authentication-required-but-there-is-no-password-setti)

```
redis (error) NOAUTH Authentication required.
```

**修改logstash配置文件**

```
input {
  redis {
    host => "redis"
    data_type => "list"
    key => "logspout"
    codec => "json"
    password => "redis"
  }
}
filter {

}
output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
  }
}

```
这里需要注意的是key，它对应的是我们日志收集后存储到redis中的key，关于key的指定方式会在后面描述。filter部分我没有添加信息，真实环境根据需要在这里添加一些日志过滤处理，比如格式化、删除无用日志等等，感兴趣可以去看下。password为redis密码

**上传配置文件到节点主机**

```
mkdir -p docker/logstash
cp conf/logstash.conf docker/logstash/logstash.conf
scp -r docker root@xxx.xxx.xxx.xxx:/
scp -r docker root@xxx.xxx.xxx.xxx:/

```

**创建logstash service**

```
docker service create --name logstash \
    --mount "type=bind,source=/docker/logstash,target=/conf" \
    --mode global \
    --network elk \
    --constraint "node.labels.elk == yes" \
    -e LOGSPOUT=ignore \
    --reserve-memory 100m \
    mywebgrocer/logstash logstash -f /conf/logstash.conf

```

**创建proxy overlay network**

```
docker network create --driver overlay proxy

```

**创建swarm-listener service**

```
docker service create --name swarm-listener \
    --network proxy \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e DF_NOTIF_CREATE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/reconfigure \
    -e DF_NOTIF_REMOVE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/remove \
    --constraint 'node.role==manager' \
    vfarcic/docker-flow-swarm-listener
    
```

**创建proxy service**

```
docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    --network proxy \
    -e MODE=swarm \
    -e LISTENER_ADDRESS=swarm-listener \
    vfarcic/docker-flow-proxy
    
```

**创建kibana service**

```
docker service create --name kibana \
    --network elk \
    --network proxy \
    -e ELASTICSEARCH_URL=http://elasticsearch:9200 \
    --reserve-memory 50m \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath=/app/kibana,/bundles,/elasticsearch \
    --label com.df.port=5601 \
    kibana:4.6
```


**比较重要的一步创建[logspout-redis-logstash service](https://github.com/rtoma/logspout-redis-logstash)**

```
docker service create --name logspout \
    --network elk \
    --mode global \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    rtoma/logspout-redis-logstash redis://redis?password=redis
    
```

其实logspout-redis-logstash是可以指定redis的key的如redis://redis?key="logspout"。因为不指定默认是logspout，我没有写默认就是logspout。所以这部分对应的就是前面logstash配置文件redis中的key值。password为redis密码

**我们自己的测试service**

```
docker service create -p 3000:3000 --name hello-service pangff/hello-service:latest

```

**访问测试服务**

```
open http://$(docker-machine ip es-swarm-1):3000/hello/123

```

**访问Kibana**

```
open http://$(docker-machine ip es-swarm-1)/app/kibana

```

配置index，然后Discover，搜索hello结果如图（访问一次再看，会发现结果变多一条）

![](http://www.pffair.com/images/65.png)


*如果访问Kibana后在创建logstash-**默认索引时候下面是灰色没有mapper时，说明elasticsearch没有收到日志。如果在创建logstash-默认索引时候可以创建但是Time-field name没有内容时候，说明日志格式问题或者Elasticsearch出现异常*


### 备注

**查看redis container中logspout内容**

查看redis在哪个节点

```
docker service ps redis

```

进入redis对应主机

```
docker-machine ssh es-swarm-1

```

查看redis container id

```
docker ps -a

```

找到redis容器id进入容器（2361aa523cd1是redis容器id）

```
docker exec -it 2361aa523cd1 /bin/bash

```

访问redis

```
redis-cli
```
查看key为logsput类型为list的数据前10条


```
LRANGE logspout 0 10

```


### 后续需要处理
* 是否有循环日志采集问题，比如统计到elasticsearch日志后，日志进入elasticsearch本身也会出现日志，这样造成循环
* 在正式环境下该日志处理架构的节点编排、network处理
* elasticsearch的数据备份，磁盘扩容
* 该日志处理架构下，个个节点性能指标
* 该日志能否按需求收集相关日志,需要后续根据业务测试
* [kibana](https://www.elastic.co/blog/kibana-4-video-tutorials-part-1)的深入学习
