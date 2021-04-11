---
layout: post
title: "logspout-elk"
date: 2017-01-15 19:00:35 +0800
comments: true
categories: docker
---

接上篇[elk-docker](http://www.pffair.com/blog/2017/01/12/elk-docker/)，在docker swarm环境部署好了elk，如何在swarm环境进行日志收集呢？本文使用logspout进行swarm中每个节点的日志收集并发送给logstash，logstash将日志存入elasticsearch中，kinana从elasticsearch读取日志信息进行展示。

<!--more-->

### 创建logspout service

使用以下命令进行logspout service创建

```
docker service create --name logspout \
    --network elk \
    --mode global \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e SYSLOG_FORMAT=rfc3164 \
    gliderlabs/logspout syslog://logstash:51415

```
创建global的logspout servive因为我们要在每一container上进行日志监控。将logspout service加入elk network，以便于和之前的logstash service进行通信。在服务启动的时候执行syslog://logstash:51415告诉logspout我们要使用syslog协议发送日志到在51415端口运行的logstash

查看logspout service状态

```
docker service ps logspout
```

![](http://www.pffair.com/images/64.png)

等到logspout启动完成。我们用一个小例子看看logspout是否真的把日志发送给了logspout。[例子代码](https://github.com/MarshalW/hello-service)

创建基于restify的 [hello-service]((https://github.com/MarshalW/hello-service))

```
docker service create -p 3000:3000 --name hello-service marshalw/hello-service:0.1.0

```

查看hello-service状态

```
docker service ps hello-service

```
等待hello-service完全启动后，运行查下

```
open http://$(docker-machine ip es-swarm-1):3000/hello/name

```


通过以下几个命令查看logstash对应container的日志

用以下查看当前节点全部container信息，并找到logstash对应 container id

```
docker ps -a

```
用以下命令查看logstash日志信息（命令中65b7825aef55是上面找到的logstash container id）

```
docker logs 65b7825aef55

```

可以发现以下日志条目。（因为我们的logstash是global的，每次日志发送不一定发送到了当前节点的logstash上来，要么通过多访问几次hello-service的方式，要么发现本节点没有就去另外的节点按相同方法找）

```
{
           "message" => "restify listening at http://[::]:3000\n",
          "@version" => "1",
        "@timestamp" => "2017-01-15T12:09:18.000Z",
              "host" => "10.0.0.12",
          "priority" => 14,
     "timestamp8601" => "2017-01-15T12:09:18Z",
         "logsource" => "65b7825aef55",
           "program" => "hello-service.1.9zdbccrwv7q7yj8qpeg82kbr6",
               "pid" => "12204",
          "severity" => 6,
          "facility" => 1,
         "timestamp" => "2017-01-15T12:09:18Z",
    "facility_label" => "user-level",
    "severity_label" => "Informational"
}

```

说明我们hello-service的日志的确是发送到了logstash中。

运行

```
open http://$(docker-machine ip es-swarm-1)/app/kibana
```
启动kibana，配置一个index可以在kibanna中看到我们hello-service的访问日志

