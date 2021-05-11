---
layout: post
title: "Mac操作Raspberry安装ubuntu sever 20.04"
date: 2021-05-04 21:02:45 +0800
comments: true
categories: 系统
---


入手两个树莓派4B便于本地做一些测试，记录下通过Mac给树莓派刷centos 7.9系统的过程

<!--more-->

### 首先格式化TF卡

TF放入读卡器，读卡器插到Mac上，终端执行

```
diskutil list
```

确认下哪一个是要烧录系统的内存卡（我的是**/dev/disk2**）


执行如下命令格式化内存卡**/dev/disk2**

```
sudo diskutil eraseDisk FAT32 TFCARD MBRFormat /dev/disk2
```

执行

```
df -h
```

确认下格式化情况

解除挂载

```
sudo diskutil unmount /dev/disk2s1
```

### 烧录系统

下载ubuntu 20.04.2,[官方镜像](https://cdimage.ubuntu.com/releases/20.04/release/ubuntu-20.04.2-preinstalled-server-armhf+raspi.img.xz)

烧录镜像

```
sudo dd bs=1m if=镜像下载目录 of=/dev/rdisk2 conv=sync
```

### 启动树莓派

* TF卡从读卡器取出，放到树莓派卡槽，树莓派连接连接电源启动
* 树莓派通过网线连接到路由器，从路由器查看连接设备找到树莓派的ip

ssh 登录树莓派，系统默认账号(ubuntu/ubuntu)

```
ssh ubuntu@树莓派ip 
```

登录后要修改密码


### 调整磁盘

登录系统后

```
df -h
```

发现系统磁盘大小不对，执行如下脚本

```
#!/bin/bash

clear

part=$(mount |grep '^/dev.* / ' |awk '{print $1}')

if [ -z "$part" ];then

    echo "Error detecting rootfs"

    exit -1

fi

dev=$(echo $part|sed 's/[0-9]*$//g')

devlen=${#dev}

num=${part:$devlen}

if [[ "$dev" =~ ^/dev/mmcblk[0-9]*p$ ]];then

    dev=${dev:0:-1}

fi

if [ ! -x /usr/bin/growpart ];then

    echo "Please install cloud-utils-growpart (sudo yum install cloud-utils-growpart)"

    exit -2

fi

if [ ! -x /usr/sbin/resize2fs ];then

    echo "Please install e2fsprogs (sudo yum install e2fsprogs)"

    exit -3

fi

echo $part $dev $num

 

echo "Extending partition $num to max size ...."

growpart $dev $num

echo "Resizing ext4 filesystem ..."

resize2fs $part

echo "Done."

df -h |grep $part

```

执行后，磁盘恢复正常


### 配置WIFI

编辑配置文件

```
sudo vi /etc/netplan/50-cloud-init.yaml
```

```
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        eth0:
            dhcp4: true
            optional: true
    version: 2
    wifis:
        wlan0:
            dhcp4: true
            optional: true
            access-points:
                "你的无线SSID":
                    password: "你的无线密码"
                "你的无线SSID"2:
                	password: "你的无线密码"

```

```
sudo netplan generate
```

```
sudo netplan apply
```

查看连接情况(wlan0 自动获取到ip即可)

```
ip a
```

### 配置sshkey，免密登录

```
ssh-copy-id -i .ssh/id_rsa.pub ubuntu@树莓pi到IP

```

### 修改下主机名

```
hostname pi
```

### 安装docker注意


按照官方按照方式

armhf 架构,发现 https://download.docker.com/linux/ubuntu/dists/focal 下没有对应的armhf的容器版本可以安装

```
echo \
  "deb [arch=armhf signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

```

运行 lsb_release -cs 

```
ubuntu@pi:~$ lsb_release -cs 

focal
```

lsb_release得知版本号位focal，根据软件向下兼容的原则，focal版本高于bonic,所以存储库路径可以使用bonic版本代替focal版本，此处用bonic代替(lsb_release -cs) 即可

```
echo   "deb [arch=armhf signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu bionic stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 将当前用户加入docker组，免sudo

```
sudo usermod -aG docker ubuntu
```

### 安装docker-compose

```
sudo apt-get update
```

安装python pip
```
sudo apt-get install -y libffi-dev libssl-dev

sudo apt-get install -y python3 python3-pip

```

安装docker-compose

```
sudo pip3  install docker-compose=1.29.1

sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
```

查看版本
```
docker-compose version
```