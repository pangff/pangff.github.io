---
layout: post
title: "模仿iBooks的点击图书打开动画"
date: 2014-06-19 11:32:10 +0800
comments: true
categories: Android
---
####先看下要实现的打开书动画的最终效果

![](http://www.pffair.com/images/6.png)

<!--more-->
在实现这种效果的动画之前已经有了一个OpenGL ES翻页效果的实现，但是只是单本书从屏幕中间开始放大打开的效果并不能满足目前的多本书移动放大打开情况。具体单本书动画效果demo参考项目：

	https://github.com/pangff/BookOpen
	
下面来说多本书的情况，为了达到好的体验效果整个动画我们不能奢望使用基本动画来实现这个效果（android基本动画跑在UI线程中，对于复杂动画，多个基本动画协调会影响效率），所以OpenGL ES是唯一的选择。

####实现原理：
初始化页面很简单，就是一个GridView上放一些书籍图片，接下来讲从GridView指定位置开始的动画实现。
开始之前首先需要对透视投影有初步了解，参考文章：

	http://www.easymorse.com/index.php/archives/1044
	http://www.easymorse.com/index.php/archives/1054
	
看过了透视投影的参考文章我们需要知道：

	透视投影的视窗如果设置为屏幕宽高的话，横向x轴最左边是-ratio、最右边是ration。纵向y轴最上面是	1、最下面是-1。如果我们将近平面放到（0，0，0）点，那么该平面在x轴方向的宽度正好是2*ratio，在	y轴方向上的高度正好是2。也就是说近平面正好占满屏幕（这样会方便之后的计算）
	
![](http://www.pffair.com/images/7.png)

	模型只能在近平面到远平面之间的视锥中做矩阵变换显示，出了视锥就不能显示了；

	对于透视投影当我们沿着Z轴正方向移动模型时，模型会在从远及进也就是在视觉效果上会从小到大。

![](http://www.pffair.com/images/8.png)

知道这三点，那我们就会产生这样的思路：

我们将近平面放到(0,0,0) 。那么要实现最终的效果，只需要初始化的时候将模型放到距离近平面足够远的地方以达到在视觉上图片缩小到指定大小（在Gridview上大小）的效果；然后在动画开始的时候将图片从初始位置向近平面移动，这样就会出现在视觉上图片从初始化（Gridview上大小）放大到屏幕大小的效果。在这中间还要同时实现将图片从初始位置到屏幕中心的移动以及沿y轴的旋转。

####具体实现：

整个动画效果从指定位置、指定大小移动到屏幕中心放大旋转打开到充满屏幕如图

![](http://www.pffair.com/images/9.png)

所以要将整个透明GLSurfaceView充满屏幕，覆盖Gridview，然后根据算法初始化时在GLSurfaceView上绘制的图片正好遮挡Gridview原始位置的图片，然后再做动画的矩阵变换。

####算法：

先计算图片模型应该初始化到位置才能使其沿z轴向前移动到近平面后正好充满屏幕，如图,相当与将ratio大小的平面向前移动到0后，眼睛只能看到该平面的一部分

![](http://www.pffair.com/images/10.png)

我们现在已知near、right、left、ratio要求的是0点到n点的距离。根据相似三角形容易得到
	
	(right-left)/2*ratio=near/(near+on)

所以

	on=2*ratio*near/(right-left)-near

为了计算简便，我们初始的时候将图片放到z＝0也就是近平面（x，y）平面上，并让图片中心在x=0，y=0的点，然后在第一桢的时候再移动到在on位置对应的坐标上。所以我们要计算出第一祯时图片在on时的坐标位置。如图

![](http://www.pffair.com/images/11.png)

已知图片模型为AB，A点x坐标为right、B点x坐标为left，当AB从z＝0移动on时求A’、B’ 的坐标。根据相似三角行，我们知道

	oB/oB’=oe/ne
	
也就是

	left/left’=near/(near+od)

所以

	left’=left(near+od)/near
	right’=right(near+od)/near

同理

	top’=top(near+od)/near
	bottom’=bottom(near+od)/near

####至此我们只需要实际变换：

* 将模型的中心点从(left’+(right’-left’)/2,top’+(bottom’-left’)/2)移动到(0,0)。这里我在代码中nd指的是od、factor是每一祯的变化因子（factor在指定时间从0变化到1），同时将模型从z=-od移动到z＝0
	
		Matrix.translateM(modelMatrix, 0, (newleft+Math.abs(newright-newleft)/2)*(1-factor), (newtop-Math.abs(newbottom-newtop)/2)*(1-factor),-nd*(1-factor));

* 做绕y旋转90度，旋转参考 http://www.easymorse.com/index.php/archives/1054
	
		Matrix.translateM(modelMatrix, 0, -ratio, 0, 0f);
		Matrix.rotateM(modelMatrix, 0, -90 * factor, 0, 1, 0);
		Matrix.translateM(modelMatrix, 0, ratio, 0, 0);
	
####到这里关键的算法就完成了。具体项目请参考

	https://github.com/pangff/MutiBookOpen
