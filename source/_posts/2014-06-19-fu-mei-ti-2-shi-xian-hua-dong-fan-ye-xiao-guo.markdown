---
layout: post
title: "富媒体2-实现滑动翻页效果"
date: 2014-06-19 15:22:56 +0800
comments: true
categories: android
---
实现了图文混排<http://www.easymorse.com/index.php/archives/1464>，现在我们打算实现WebView上每一栏作为一页的滑动翻页效果，而不是简单的通过滚动的滑动来浏览后面的内容。
<!--more-->

####实现思路：
这里有两种实现方式

* 禁用横向滚动条，直接使用js通过scrollLeft实现翻页滑动。
* 将WebView的每一屏预先截图，然后通过简单的ViewPager实现滑动浏览（其实每一页是图片）
第一种方式简单实践后效果不好，不能随手势滑动，如果采用animation滑动效果会抖动。所以我们采用第二种方式
效果

![](http://www.pffair.com/images/21.png)

####具体实现：
页面架构

![](http://www.pffair.com/images/22.png)

翻页逻辑

![](http://www.pffair.com/images/23.png)

####参考项目：

	https://github.com/pangff/RM/tree/m2