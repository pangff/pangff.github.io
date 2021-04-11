---
layout: post
title: "趟Android L "
date: 2014-07-24 18:30:28 +0800
comments: true
categories: Android
---
android L 发布一段时间了，抽时间趟了一下，做一下总结。
<!--more-->
* 环境变化，最大变化就是虚拟机从Dalvik变为了ART(在4.3已经引入，但是androidL已经作为默认运行环境)
* ART采用预编译（接收dex文件输入，输出目标机器可执行文件），速度当然要比Dalvik快，同时在垃圾回收，和调试方面都有提升
* 接下来是通知API上的改进
为了用户隐私去掉了ActivityManager.getRecentTasks()，ActivityManager.getAppTasks()只能得到本应用信息
* 界面上的变化,采用了Material design
* 添加了锁屏通知Lockscreen notifications
* WebView 升级到 Chromium M36，可以支持（ WebAudio, WebGL, and WebRTC）
* 绘图的变化。支持OpenGL ES 3.1
* 媒体方面变化。Camera API变化 AudioTrack API变化 MediaController变化
* 存储方面的变化
* 网络传输变化
* 蓝牙广播
* NFC提升
* 电池效率
* 电池使用测量的开发工具