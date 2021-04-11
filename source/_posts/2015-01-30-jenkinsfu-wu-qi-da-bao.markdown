---
layout: post
title: "jenkins服务器打包"
date: 2015-01-30 14:49:51 +0800
comments: true
categories: [Android, 备忘, 服务端]
---
android项目中要批量多渠道打包，所以使用了ant脚本。但是因为每个人本地环境不同、操作系统不同经常要修改打包文件，而且每次打包都要占用一定时间。为了减少重复工作方便任何人无障碍打包，就要将打包环境部署到服务器，而且使用jenkins持续集成更加方便。下面简单说下部署步骤。
<!--more-->
1、安装jenkins（以linux上安装为例）

	sudo apt-get install jenkins
	/**当然你也可以下载jenkins.war在web服务器下部署**/

2、启动服务(默认是8080端口，可以通过修改配置文件修改端口)

	http://server_ip:8080
	/**如果每启动看下是不是端口占用**/
	
	/**如果没有占用，手动启一下**/
	service jenkins start

3、启动后页面(我已经创建了一个test项目)，出现jenkins页面说明成功了

![](http://www.pffair.com/images/31.png)


4、新建项目

![](http://www.pffair.com/images/32.png)

5、项目地址配置(我这里用的是git，如果是svn的话那么就选择subversion选项)

![](http://www.pffair.com/images/33.png)

6、打包的ant target 以及文件(默认是项目根目录的buildx.xml)

![](http://www.pffair.com/images/34.png)

7、保存配置，立即构建（忽然发现服务器还没有android打包环境）

![](http://www.pffair.com/images/35.png)

8、服务器安装ant、android打包环境。改写build.xml文件配置适应服务器环境

9、重新构建，打包完成