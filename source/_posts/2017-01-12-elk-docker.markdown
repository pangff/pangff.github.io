---
layout: post
title: "elk-docker"
date: 2017-01-12 23:18:34 +0800
comments: true
categories: docker
---

本文接上篇[ecs-docker-swarm](http://www.pffair.com/blog/2017/01/11/ecs-docker-swarm/),在实现ESC docker swarm并添加es-swarm-2 label:elk=yes基础上部署elk(elasticsearch、logstash、kibana),其中elasticsearch部署到label中elk=yes的节点也就是es-swarm-2

<!--more-->

上文中的环境:

* es-swarm-1(manager)
* es-swarm-2(worker,label:elk=yes)


### 创建elk overlay
 创建以elk命名的overlay network，之后elk的通信将通过elk overlay
 
```
eval $(docker-machine env swarm-1)

docker network create --driver overlay elk

```
### 创建elasticsearch service

 创建global的elasticsearch service，并且通过constraint(参考[docker-constraint](http://www.pffair.com/blog/2017/01/04/docker-constraint/))限制elasticsearch只能创建部署到label中elk＝yes的节点，也就是es-swarm-2节点
 
```
docker service create --name elasticsearch \
    --mode global \
    --network elk \
    -p 9200:9200 \
    --constraint "node.labels.elk == yes" \
    --reserve-memory 500m \
    elasticsearch:2.4
    
```

因为后续的logstash servcie要依赖elasticsearch service所以要确保elasticsearch service完全启动后再去创建logstash。
如果是单独命令运行，只要用

```
docker service ps elasticsearch

```
去检查下elasticsearch的CURRENT STATE是不是Running,不是就等会儿。通过这个命令我们还可以看到elasticsearch在个个节点部署状态,下图可以看到elasticsearch已经运行，而且只有在es-swarm-2上是Running。

![](http://www.pffair.com/images/63.png)

当然如果只是查看是否启动成功也可以

```
open http://$(docker-machine ip es-swarm-1):9200
```
直接打开浏览器看是否可以访问



如果elk整个启动是在一个脚本中运行，那就需要做一个等待处理。有很多方法，我这里采用的是过滤获取docker service ps命令日志信息来判断（方法自己感觉不是很好，如果有好办法欢迎指正）
 
```

while true; do
    REPLICAS=$(docker service ps elasticsearch | grep es-swarm-2 | awk '{print $7}')
    echo "REPLICAS:"$REPLICAS
    A=$(docker service ps elasticsearch | grep es-swarm-2 | awk '{print $0}')
    echo $A
    if [[ $REPLICAS == "Running" ]]; then
        sleep 5
        echo "elasticsearch Running..."
        break
    else
        echo "Waiting for the elasticsearch service..."
        sleep 5
    fi
done
```

### 创建logstash service

添加logstash的配置文件，因为默认logstash的配置是

```
input {
    stdin {}
    syslog {}
}
```
我们要将logstash收集的日志输出到elasticsearch所以要创建配置文件，并再通过 mount让logstash读取修改后的配置

在本地创建config/logstash.conf,并修改为以下内容

```
input {
  syslog { port => 51415 }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
  }
  # Remove in production
  stdout {
    codec => rubydebug
  }
}


```

为了后面目录整齐，便于管理，我们创建统一docker目录。对于logstash的配置文件我们放到logstash目录中。并将docker目录传到两台ECS，也就是docker node上

```
mkdir -p docker/logstash
cp conf/logstash.conf docker/logstash/logstash.conf
scp -r docker root@xxx.xxx.xxx.xxx:/
scp -r docker root@xxx.xxx.xxx.xxx:/
```
创建logstash service。logstash service是global的，目前并没有通过label去限制logstash（正式环境视情况定），加入elk network，我们将上传到ECS的目录bind到了logstash的conf下，指定logstash的conf配置在/conf/logstash.conf。配置环境变量LOGSPOUT=ignore为后续logspout做准备

```
docker service create --name logstash \
    --mount "type=bind,source=/docker/logstash,target=/conf" \
    --mode global \
    --network elk \
    -e LOGSPOUT=ignore \
    --reserve-memory 100m \
    logstash:2.4 logstash -f /conf/logstash.conf
```

同样如果在一个脚本中，一样等待启动完成

```
while true; do
    REPLICAS=$(docker service ps logstash | grep es-swarm-2 | awk '{print $7}')
    echo "REPLICAS:"$REPLICAS
     A=$(docker service ps logstash | grep es-swarm-2 | awk '{print $0}')
    echo $A
    if [[ $REPLICAS == "Running" ]]; then
        sleep 5
        echo "logstash Running..."
        break
    else
        echo "Waiting for the logstash service..."
        sleep 5
    fi
done

```

创建代理proxy overlay network。proxy用于代理与个个service间通信

```
docker network create --driver overlay proxy

```

通过swarm-listener、docker-flow-proxy实现[swarm-mode-auto](http://proxy.dockerflow.com/swarm-mode-auto/)。swarm-listener监控swarm service的创建销毁事件，当service创建销毁时自动发送请求给docker-flow-proxy进行重新配置([reconfigure](http://proxy.dockerflow.com/usage/#reconfigure))。

创建swarm-listener service。-e环境变量意义部分参考文章[swarm-mode-auto](http://proxy.dockerflow.com/swarm-mode-auto/)

```
docker service create --name swarm-listener \
    --network proxy \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e DF_NOTIF_CREATE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/reconfigure \
    -e DF_NOTIF_REMOVE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/remove \
    --constraint 'node.role==manager' \
    vfarcic/docker-flow-swarm-listener
    
```

创建proxy service。80 http请求，443 https请求。外部请求通过proxy代理到目标service

```
docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    --network proxy \
    -e MODE=swarm \
    -e LISTENER_ADDRESS=swarm-listener \
    vfarcic/docker-flow-proxy

```

一个shell脚本运行，确保服务启动。通过service ls的 replicas=1/1 确保swarm-listener 和 proxy启动完成

```
while true; do
    REPLICAS=$(docker service ls | grep swarm-listener | awk '{print $3}')
    REPLICAS_NEW=$(docker service ls | grep swarm-listener | awk '{print $4}')
    if [[ $REPLICAS == "1/1" || $REPLICAS_NEW == "1/1" ]]; then
        break
    else
        echo "Waiting for the swarm-listener service..."
        sleep 5
    fi
done

while true; do
    REPLICAS=$(docker service ls | grep proxy | awk '{print $3}')
    REPLICAS_NEW=$(docker service ls | grep proxy | awk '{print $4}')
    if [[ $REPLICAS == "1/1" || $REPLICAS_NEW == "1/1" ]]; then
        break
    else
        echo "Waiting for the proxy service..."
        sleep 5
    fi
done

```

创建kibana service 并等待完成。kibana中的label作用参考[swarm-mode-auto](http://proxy.dockerflow.com/swarm-mode-auto/)

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

一个脚本运行时，确保服务启动

```

while true; do
    REPLICAS=$(docker service ls | grep proxy | awk '{print $3}')
    REPLICAS_NEW=$(docker service ls | grep proxy | awk '{print $4}')
    if [[ $REPLICAS == "1/1" || $REPLICAS_NEW == "1/1" ]]; then
        break
    else
        echo "Waiting for the proxy service..."
        sleep 5
    fi
done


```

访问kibana

```
open http://$(docker-machine ip es-swarm-1)/app/kibana

```

至此，在swarm mode 中部署elk完成。
完整脚本参考[dm-swarm-services-elk](https://github.com/pangff/docker-swarm-sh/blob/master/scripts/dm-swarm-services-elk.sh)

[后续将通过logspout进行日志采集并发送到logstash再到elasticsearch，并通过kibana进行查看的例子 >>>]()