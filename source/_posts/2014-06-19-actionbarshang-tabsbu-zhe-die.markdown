---
layout: post
title: "ActionBar上Tabs不折叠"
date: 2014-06-19 11:50:07 +0800
comments: true
categories: android
---
用过ActionBar Tabs的同学应该都有遇到过这样的问题 如图，在竖屏的时候Tabs是展开显示的

![](http://www.pffair.com/images/12.png)

而在横屏的时候呢？

![](http://www.pffair.com/images/13.png)

是的Tabs折叠起来了，Google为我们做了选择。但是有的时候真的不想让Tabs折叠起来，无论横竖就要Tabs展开，该怎么办呢？
研究了很久终于发现，原来只需要将

 	actionBar.setNavigationMode(ActionBar.NAVIGATION_MODE_TABS);
 
放到

 	actionBar.addTab(actionBar.newTab().setText(“tabs”));
 
之后
来看下效果吧

![](http://www.pffair.com/images/14.png)

参考项目（其实是根据官网demo改的）
官网参考

	http://developer.android.com/training/implementing-navigation/lateral.html#horizontal-paging

项目demo

	https://github.com/pangff/NoCollapseTabs