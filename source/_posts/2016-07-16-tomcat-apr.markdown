---
layout: post
title: "tomcat https"
date: 2016-07-16 19:41:31 +0800
comments: true
categories: tomcat
---
https也就是经过ssl加密的http，配置tomcat支持https协议其实就是tomcat SSL/TSL相关信息的配置实现。以下配置均在ubuntu环境下...

<!--more-->

配置tomcat的SSL首先说下tomcat的运行模式：

* BIO： 阻塞式I/O操作，表示Tomcat使用的是传统Java I/O操作。Tomcat7以下版本默认情况下是以BIO模式运行的。每个请求都要创建一个线程来处理，线程开销较大。高并发下表现不好。（阻塞IO采用流方式传输）
*  NIO：基于Java NIO。是一个基于缓冲区、并能提供非阻塞I/O操作的Java API（相较阻塞IO的流方式传输，NIO采用块方式传输，将整个流分块再拼装，非阻塞原因在于它内部有一个单独数据监听线程进行块数据的分发，这样工作线程可以有多个）
* APR： 在操作系统级别解决异步IO问题，当然在并发和性能上比前两个都好

Tomcat 能够使用两种 SSL 实现：

* JSSE 实现，它是Java 运行时（从 1.4 版本起）的一部分。JSSE（Java SecuritySocket Extension，Java安全套接字扩展）是Sun为了解决在Internet上的安全通讯而推出的解决方案。它实现了SSL和TSL（传输层安全）协议。在JSSE中包含了数据加密，服务器验证，消息完整性和客户端验证等技术。通过使用JSSE，开发人员可以在客户机和服务器之间通过TCP/IP协议安全地传输数据。这篇文章主要描述如何使用JSSE接口来控制SSL连接。

* APR 实现，默认使用 OpenSSL 引擎。


## JSSE实现


JSSE实现很简单，只要修改tomcat/conf/server.xml 添加如下配置

```xml

<!-- Define a HTTP/1.1 Connector on port 8443, JSSE NIO implementation -->
<Connector protocol="org.apache.coyote.http11.Http11NioProtocol"
           port="8443" .../>

<!-- Define a HTTP/1.1 Connector on port 8443, JSSE NIO2 implementation -->
<Connector protocol="org.apache.coyote.http11.Http11Nio2Protocol"
           port="8443" .../>

<!-- Define a HTTP/1.1 Connector on port 8443, JSSE BIO implementation -->
<Connector protocol="org.apache.coyote.http11.Http11Protocol"
           port="8443" .../> 
           
```

该配置在server.xml其实有，只是默认被注释掉了，也可以打开注释进行修改，实现https的话在也是在这个Connector进行配置，我的配置如下


```xml

 <Connector port="8443" acceptCount="100" disableUploadTimeout="true" 
               protocol="org.apache.coyote.http11.Http11NioProtocol"
               enableLookups="false"
               maxThreads="150" SSLEnabled="true" scheme="https" secure="true"
               clientAuth="false" sslProtocol="TLS" 
               keystoreFile="/Users/pangff/.keystore" keystorePass="password"/>


```
这里面涉及到了.keystore。生成也很简单

```
keytool -genkey -alias tomcat -keyalg RSA

```
然后按相关提示填写信息就可以了，最后在用户主目录会生产一个.keystore文件。当然.keystore的存放目录一定要和上面 keystoreFile的配置路径一致。之后重启tomcat 并访问 

	https://localhost:8443

如果正常访问说明配置正确。当然这时候你仍然可以通过http访问tomcat，端口还是之前的8080（如果没改过的话）


## APR实现

arp方式也是我采用的方式，废了很长时间，遇到了很多问题才成功，配置太麻烦。apr在server.xml中的配置方式和JSSE类似，如下（需要注意的是protocol的配置）

```xml

<!-- Define a SSL Coyote HTTP/1.1 Connector on port 8443 -->
<Connector
           protocol="org.apache.coyote.http11.Http11AprProtocol"
           port="8443" maxThreads="200"
           scheme="https" secure="true" SSLEnabled="true"
           SSLCertificateFile="/usr/local/ssl/server.csr"
           SSLCertificateKeyFile="/usr/local/ssl/server.key"
           SSLVerifyClient="optional" SSLProtocol="TLSv1+TLSv1.1+TLSv1.2"/>
           
```

配置完成，通过openssl生成相关证书

### 生成服务器端的私钥(key文件);

	openssl genrsa -des3 -out server.key 1024
	
运行时会提示输入密码,此密码用于加密key文件(参数des3是加密算法,也可以选用其他安全的算法),以后每当需读取此文件(通过openssl提供的命令或API)都需输入口令.如果不要口令,则可用以下命令去除口令:

	openssl rsa -in server.key -out server.key

### 生成服务器端证书签名请求文件(csr文件);
	
	openssl req -new -key server.key -out server.csr

生成Certificate Signing Request（CSR）,生成的csr文件交给CA签名后形成服务端自己的证书.屏幕上将有提示,依照其 提示一步一步输入要求的个人信息即可(如:Country,province,city,company等).

重启tomcat 访问 

	https://localhost:8443 

发现并不能访问。查看tomcat/logs/catalina.out日志文件，出现如下一个错误


	INFO: The Apache Tomcat Native library which allows optimal
	 performance in production environments was not found on the 	java.library.path

是tomcat native没有安装。该native其实已经在了，tomcat/bin/tomcat-native.tar.gz。解压进入tomcat-native-1.2.7-src/native/。运行如下命令

```
./configure

```
提示需要--with-apr=发现APR还没有安装，下面去安装APR

### 安装APR

	wget http://mirrors.cnnic.cn/apache//apr/apr-1.5.2.tar.gz
	
	wget http://mirrors.cnnic.cn/apache//apr/apr-util-1.5.4.tar.gz
	
先安装apr-1.5.2。解压后进入执行 

	./configure && make && make install


然后安装apr-util-1.5.4

	./configure  --with-apr=/usr/local/apr/ && make && make install

安装APR完成（注意--with-apr 对应目录是自己apr的安装目录）。


### 继续安装tomcat－native

解压进入tomcat-native-1.2.7-src/native/。运行如下命令

```
./configure --with-apr=/usr/local/apr/ --with-java_home=/usr/lib/jvm/default-java

```
注意如果已经配置了java_home的环境变量，那么---with-java_home=/usr/lib/jvm/default-java可以不加。

* 查看java_home环境变量方法

		echo $JAVA_HOME

* 查看jdk安装位置方法（采用whereis java并不能找到jdk安装目录）

		whereis jvm

* 配置java__home环境变量方法,终端运行（改方法只对当前shell起作用，关闭后环境变量消失）

		export JAVA_HOME=/usr/lib/jvm/default-java
	
* 采用修改.bash_profile文件配置环境变量

		vi ~/.bash_profile

		export JAVA_HOME=/usr/lib/jvm/default-java
	
再次执行

```
./configure --with-apr=/usr/local/apr/ --with-java_home=/usr/lib/jvm/default-java

```
发现又出错了，这次的错误是

	Found OPENSSL_VERSION_NUMBER 0x1000105f (OpenSSL 1.0.1e 11 Feb 2013)
	Require OPENSSL_VERSION_NUMBER 0x1000200f or greater (1.0.2)

需要升级openssl版本到1.0.2，好吧开始升级openssl



### 升级openssl

	wget http://www.openssl.org/source/openssl-1.0.2g.tar.gz 
	
	tar -xvzf openssl-1.0.2g.tar.gz 
	
	cd openssl-1.0.2g 
	
	./config 
	
	make sudo
	
	make install


安装后检查下openssl的版本 

	openssl version
	
发现还是1.0.1。检查安装目录发现和原始openssl安装目录不在一起，并没有覆盖。那么进行次配置重新安装，如下

	./config --prefix=/usr/ 
	
	make 
	
	sudo make install

再检查

	openssl version
	
终于对了


### 第三次安装tomcat－native

```
./configure --with-apr=/usr/local/apr/ --with-java_home=/usr/lib/jvm/default-java

```

成功。。。

重启tomcat，访问https://localhost:8443 正常访问


### 题外
如果要求整个应用采用https方式，那么需要在web.xml进行如下配置

```xml

<security-constraint>
    <web-resource-collection>
        <web-resource-name>securedapp</web-resource-name>
        <url-pattern>/*</url-pattern>
    </web-resource-collection>
    <user-data-constraint>
        <transport-guarantee>CONFIDENTIAL</transport-guarantee>
    </user-data-constraint>
</security-constraint>


```
将 URL 映射设为 /* ，这样你的整个应用都要求是HTTPS访问，而 transport-guarantee 标签设置为CONFIDENTIAL以便使应用支持SSL。如果你希望关闭 SSL ，需要将 CONFIDENTIAL改为NONE

## 备忘常用到的linux命令

### 解压、压缩
* .tar

		解包：tar zxvf file.tar
	
		打包：tar czvf file.tar dfile.gz
* gz　　

		解压1：gunzip file.gz
		
		解压2：gzip -d dfile.gz
		
		压缩：gzip file
　　
* .tar.gz 和 .tgz

		解压：tar zxvf FileName.tar.gz
		
		压缩：tar zcvf FileName.tar.gz DirName


### 文件查找

	find / -name filename （全局查找，可以也可以指定文件名）
	
	locate ／targetDir/fileProfix (比find快，查询指定目录以fileProfix开头文件)
	
	whereis program （只用户查找程序名）
	
	which commandName(在PATH变量指定的路径中，搜索某个系统命令的位置)
		
### 环境变量配置

	vi ~/.bash_profile

	export EVN_NAME=PATH
	

