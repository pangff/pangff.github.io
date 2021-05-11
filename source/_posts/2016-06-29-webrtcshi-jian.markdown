---
layout: post
title: "webrtc实践"
date: 2016-06-29 15:21:47 +0800
comments: true
categories: WebRTC
---
最近了解了下WebRTC，并使用SimpleWebRTC做了个简单demo，记录下实践过程以及遇到的一些问题。

<!--more-->

想要学习了解webrtc可以通过

* <https://codelabs.developers.google.com/codelabs/webrtc-web/#0/>
* <https://webrtc.github.io/samples>

以及一些WebRTC的demo一步步了解相关API。webrtc也有一些优秀的开源框架 

* [PeerJS](http://peerjs.com/)
* [EasyRTC](https://easyrtc.com/)
* [SimpleWebRTC](https://simplewebrtc.com/)

看过WebRTC一些官方开源sample，简单了解了相关通信机制

![jsep](http://www.html5rocks.com/en/tutorials/webrtc/basics/jsep.png)

两个客户端通过singnal server(信令服务器)获取到各自信息，然后两个客户端通过获取到的对方信息建立peer-to-peer的连接，通过这个连接进行数据传递。

我用的是SimpleWebRTC的一个非常简单demo


### 客户端及Web服务

```
<!DOCTYPE html>
<html>
<head>
<script src="https://simplewebrtc.com/latest-v2.js"></script>
</head>

<body>

<div id="localVideo" muted></div>
<div id="remoteVideo"></div>


<script>
var webrtc = new SimpleWebRTC({
	localVideoEl: 'localVideo',
	remoteVideosEl: 'remoteVideo',
	autoRequestMedia: true
});

webrtc.on('readyToCall', function () {
	webrtc.joinRoom('My room name');
});
</script>

</body>

</html>
		
```



```

var static = require('node-static');
var https = require('https');
var fs = require("fs");
var options = {
  key: fs.readFileSync('./key.pem'),
  cert: fs.readFileSync('./cert.pem')
};
var file = new(static.Server)();
var app = https.createServer(options,function (req, res) {
  file.serve(req, res);
}).listen(2013);

```

这儿需要注意的是必须使用https协议才可以，如果使用http启动后console会出现错误提示。使用https，key.pem 和 cert.pem是自己生成的。生成方式，下载<https://github.com/andyet/signalmaster/blob/master/scripts/generate-ssl-certs.sh>并运行就可以了，当然也可以直接通过命令，我这是比较偷懒方式。而且signalmaster后面有用到。这时候启动服务。我的服务部在182.xxx.xxx.xxx上

	node server.js

打开chrome浏览器访问<https://182.xxx.xxx.xxx:2013>选择继续前往并运行开启摄像头后，可以在浏览器上看到自己啦...


### 搭建signal server
我们使用的是开源的[signalmaster](https://github.com/andyet/signalmaster)。直接下载，然后运行node server.js就可以。当然默认是测试环境http协议，如果想要使用生产环境https协议启动需要使用 

	$ NODE_ENV=production node server.js 
	
然后修改客户端代码,添加信令服务器地址


```

var webrtc = new SimpleWebRTC({
	localVideoEl: 'localVideo',
	remoteVideosEl: 'remoteVideo',
	url:'https://182.xxx.xxx.xxx:8888',//信令服务器地址
	autoRequestMedia: true
});

```

此时打开chrome的两个标签页，访问<https://182.xxx.xxx.xxx:2013>，会发现除了本人之外多了一个图像区域，一个摄影头看不出来。可以使用在一个局域网内的两台不同设备，我用了Android设备的chrome和Mac的chrome测试，可以看到在自己的画面下方可以看到对方了。

### 不同局域网间连通问题
上面的例子在一个局域网内，或者两个独立外网主机上测试都是可以，但是如果在两个处在不同局域网的主机上测试的话会发现不能连通，这是为什么呢？

先来了解下NAT（Network Address Translation）网络地址转换，也叫做网络掩蔽或者IP掩蔽，是一种在IP封包通过路由器或防火墙时重写来源IP地址或目的IP地址的技术。位于局域网的主机如果要和局域网外主机通信，那么首先需要NAT来将内网IP翻译转换成公网IP；同样外部主机如果要和局域网中的某台主机通信，那么就需要先把目标公网IP转换成目的主机的内网IP。

NAT有几种实现方式，具体的可以看下[百科](http://baike.baidu.com/view/1580678.htm),[signalmaster](https://github.com/andyet/signalmaster)采用的是STUN方式和TURN方式，STUN方式网上有很多免费地址[signalmaster](https://github.com/andyet/signalmaster)默认用的是

	stun:stun.l.google.com:19302
	
具体可以参考[signalmaster](https://github.com/andyet/signalmaster)源码中config/production.json的stunservers配置。当然网上也有很多[免费的](https://gist.github.com/zziuni/3741933)。然而通过百科可以了解到STUN方式不支持对称NAT（而很多公司都是这种方式），所以还是需要配置TURN，见[signalmaster](https://github.com/andyet/signalmaster)config/production.json有turnservers配置。看个图

更详细的学习可以参考

<http://www.html5rocks.com/en/tutorials/webrtc/basics/>

其他:

* <https://zh.wikipedia.org/wiki/%E7%BD%91%E7%BB%9C%E5%9C%B0%E5%9D%80%E8%BD%AC%E6%8D%A2>
* <http://baike.baidu.com/view/1580678.htm>
* <https://zh.wikipedia.org/wiki/STUN>
* <https://zh.wikipedia.org/wiki/TURN>
* <http://blog.inet198.cn/?u012377333/article/details/44455183>

### 搭建TURN Server
我是在阿里云Unbuntu上安装的，signalmaster、SimpleWebRTC服务都在一起。服务器ip
182.xxx.xxx.xxx

	sudo apt-get update
	sudo apt-get install rfc5766-turn-server


配置turnserver.conf,安装完成后可能每个系统默认turnserver.conf位置不同，所以用find命令搜一下就好了

	find / -name turnserver.conf
	
然后随便找一个默认文件进行修改，或者自己在某个目录xxx下创建一个turnserver.conf， 修改turnserver.conf，添加如下配置

	#中继服务器侦听的IP，如果不写就是全部IPv4 和 Ipv6
	#listening-ip=182.xxx.xxx.xxx
	#中继服务器侦听端口
	listening-port=3478
	#tls侦听端口
	tls-listening-port=5349
	#中继服务器IP
	relay-ip=182.xxx.xxx.xxx
	#中继服务器处理连接线程数
	relay-threads=50
	
	#TURN服务器公开/私有的地址映射,这个适用于服务器在NAT后进行服务器内外网映射,如果不是这种情况可以为空或者公网ip
	#external-ip=182.xxx.xxx.xxx
	
	#使用凭证机制
	lt-cred-mech
	
	#用户配置
	userdb=/etc/turnuserdb.conf
	
	#域配置
	realm=pffair.com
	pidfile=“/var/run/turnserver.pid”
	
	
turnuser.conf 配置如下

	username:password

启动turnserver

	turnserver -c turnserver.conf
	
访问<https://182.xxx.xxx.xxx:3478> 此时能看到TUTN Server文本，说明启动成功

然后启动signalmaster server 、SimpleWebRTC server。这时候就可以进行两台不同局域网间主机通信了