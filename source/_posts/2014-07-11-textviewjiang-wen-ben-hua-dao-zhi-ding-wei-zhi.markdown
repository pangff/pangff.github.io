---
layout: post
title: "Canvas将文本画到指定位置"
date: 2014-07-11 19:07:06 +0800
comments: true
categories: Android
---
经常会遇到使用Canvas绘制文字的情况，但是我们会发现使用canvas.drawText("string",x,y,paint)的时候画出的效果不是想象中按文字左上角坐标来的。那么文字位置究竟是怎么样的呢？
<!--more-->

x坐标和gravity有关，这里不做详细讨论

来看高度我们直接盗个图来看下

![本图来自csdn博客http://blog.csdn.net/wen0006/article/details/5712001](http://www.pffair.com/images/30.png)

根据图片我可以看到有几个基准线

* baseLine:我们可以理解为y坐标轴的0点,横轴，（它其实是drawText中的y)
*  paint.getFontMetrics().bottom: bottom到biseline的距离
*  paint.getFontMetrics().top: top到biseline的距离(在横纵上放所以为负值)
*  paint.getFontMetrics().ascent: ascent到biseline的距离(在横纵上放所以为负值)
* paint.getFontMetrics().descent: descent到biseline的距离(在横纵上放所以为负值)

接下来我们可以模拟一个场景：
要把一个文本绘制到一个已知矩形的中心centerY，那么我们改如何计算文本的baseline 呢？

根据简单几何知识可得
```java
int baseline = (int) (rectF.centerY()+(paint.getFontMetrics().bottom-paint.getFontMetrics().top)/2-paint.getFontMetrics().bottom);

```