---
layout: post
title: "混淆后代码异常处理"
date: 2015-03-10 14:26:54 +0800
comments: true
categories: Android
---
release版本的apk经常会通过一些三方统计平台（比如友盟、flurry等等）进行错误收集。然而由于release版本一般要通过混淆，混淆后的异常堆栈很难读取。该如何处理呢？
<!--more-->

#### 方法一 保留mapping文件使用proguardgui转换查看###
android开发人员都知道，使用ant打包之后会生成一个mapping.txt的混淆映射文件。然后使用android sdk目录下的proguardgui可视化转换工具进行reTrace转换。可以将不容易读取的异常堆栈转换成好理解定位代码的信息

proguardgui所在位置

```
	<android-sdk-home>/tools/proguard/bin/proguardgui.sh 
	(windows的话是proguardgui.bat)

```

打开图形界面，如图

![](http://www.pffair.com/images/36.png)

使用方法：

* 选择ReTace
* 在mapping file区域选择打包时产生的mapping文件
* 在Obfuscated stack trace区域粘贴异常堆栈
* 点击右下角的ReTrace！按钮
* 在De-obfuscated stack trace 区域可以看到转换后的好理解的异常信息

转换后的效果，如图

![](http://www.pffair.com/images/37.png)

#### 方法二 直接读mapping文件###

直接读取mapping有一定难度，需要搞懂一些规则：

mapping文件中$的含义：

```
$是内部类的意思，比如 :
 	com.pffair.Test$MainTest 指的是Test类中的内部类MainTest
 	com.pffari.Test$1 指Test类中的第一个匿名内部类 其中1代表第几个，按前后顺序

```

mapping文件中access$xxx的含义：

```
access$xxx指内部类中调用的外部类方法或对象 ，例如:
 	java.util.List access$100(com.pffair.Test) 
 	指在Test类的某个内部类中第1个位置引用了外部类Test的私有成员（变量或方法）
 	其中100中后两位代表类型，00表示对象或者函数，02代表基本数据类型。
 	后两位前面的数字表示出现的顺序从0开始

```
搞明白了这两点，mapping文件基本就能理解个大概了。当然其中还有比较复杂的内部类嵌套等问题，但是按上面的两点嵌套读取就可以了


