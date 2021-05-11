---
layout: post
title: "harbor v2.2.1安装及配置"
date: 2021-05-11 15:30:09 +0800
comments: true
categories: docker
---


记录下SLB（https-http)->docker-nginx->harbor-nginx->harbor的配置过程 harbor版本v2.2.1

<!--more-->

下载安装包

```
wget https://github.com/goharbor/harbor/releases/download/v2.2.1/harbor-online-installer-v2.2.1.tgz
```


解压缩

```
tar -xvf harbor-online-installer-v2.2.1.tgz

```

进入harbor目录

```
cd harbor
```

修改harbor.yml配置文件(hostname，注释https，修改密码)

```
# Configuration file of Harbor

# The IP address or hostname to access admin UI and registry service.
# DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
hostname: host
# http related config
http:
  # port for http, default is 80. If https enabled, this port will redirect to https port
  port: 80
  relativeurls: true
# https related config
# https:
#   # https port for harbor, default is 443
#   port: 443
#   # The path of cert and key files for nginx
#   certificate: /your/certificate/path
#   private_key: /your/private/key/path

# internal_tls:
#   # set enabled to true means internal tls is enabled
#   enabled: true
#   # put your cert and key files on dir
#   dir: /etc/harbor/tls/internal

# Uncomment external_url if you want to enable external proxy
# And when it enabled the hostname will no longer used
  external_url: https://host
```

由于前置nginx的反向代理，因此需要增加 relativeurls: true  、 external_url 配置

运行安装脚本

```
./install.sh
```

安装过程中会自动在根创建docker-compose.yml文件并启动相应的container。因为我们之前 已有一个名字是nginx的容器，启动时会报错，提示nginx名称已被其他容器使用。 我们将相关启动容器停止，进行docker-compose.yml文件修改

### 停止相关容器

```
docker-compose down -v
```

#### 修改harbor/docker-compose.yml 


修改nginxl配置

```
proxy:
  image: goharbor/nginx-photon:v2.2.1 container_name: harbor-nginx (nginx改成harbor-nginx) restart: always
   ....
  ports:
    - 9000:8080 端口也改下，80:8080改成9000:8080因为公共nginx已经使用80了

```

因为我们已经有了公共的nginx代理服务，所以并不打算直接从外部访问 harbor的nginx代理， 而是通过公共的nginx服务反响代理到harbor-nginx的 proxy。如果要在公共nginx中可以通过容 器名称直接访问到harbor-nginx，那么就需要他们都在同一个网络环境内，所以修改docker- compose.yml文件的网络名称为公共nginx对应网络名称，并配置使用外部网络


修改网络配置

```
networks:
  ds-netwrok: (harbor名字改成了ds-network。docker-compose.yml其他部分使用了harbor网络的都要改成ds-network)
    external: true (false 改成 true代表使用外部已有的网络而不是再创建)
```

#### 修改registry config

common/config/registry/config.yml http下增加 relativeurls配置

```
http:
  relativeurls: true
```

#### 修改nginx配置

common/config/nginx/nginx.conf ，所有配置中注释以下语句

```
 proxy_set_header X-Forwarded-Proto $scheme;
```

#### 修改core env

common/config/core/env

```
EXT_ENDPOINT=http://host
```
改为

```

EXT_ENDPOINT=https://host

```

#### 启动容器

```
docker-compose up -d
```


### 前置nginx反向代理的配置(因为前面还有SLB负载均衡，SLB做了443到服务器80的监听配置，并前置了SSL证书，所以这里只需要80)

```
server {
    listen 80;
    server_name host;
    client_max_body_size 100M;
    location / {
        resolver 127.0.0.11 ipv6=off;
        set $service_upstream "http://harbor-nginx:8080";
        proxy_set_header  Host              $http_host;
        proxy_set_header  X-Real-IP         $remote_addr;
        proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header  X-Forwarded-Proto $scheme;

        proxy_buffering off;
        proxy_request_buffering off;

        # Fix the "It appears that your reverse proxy set up is broken" error.
        # proxy_read_timeout  90;
        proxy_pass $service_upstream;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```