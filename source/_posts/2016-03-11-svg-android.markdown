---
layout: post
title: "关于矢量路线图动态路径在Android实现方案"
date: 2016-03-11 12:00:42 +0800
comments: true
categories: Android
---

最近遇到svg路线图渲染问题，查一些资料总结下解决方案

<!--more-->

### 方案一：svg＋VectorDrawable

优势：

- Android在5.0以后开始支持VectorDrawable矢量图渲染
- Android Support Library 23.2已经提供向下兼容

缺点：

- 不是全部svg标签都支持，因为svg本身没有完善规范；所以需要修改svg标签到vector支持的标签这个也有三方库去做转化
- 不支持动态矢量节点的修改如果要达到路径动态渲染需要内存中修改节点内容，重新渲染到ImageView，速度问题需要验证
- 大图加载速度问题需要验证
- 内存问题需要验证

###  方案二：纯三方库 

AndroidSVG：

- 支持svg1.1 － 1.2 大部分标签

- 网址: https://code.google.com/p/androidsvg/

- 最新release:  1.2.2-beta-1 (16 June 2014)，还在维护1.3版本有计划提出
- 已知问题：

    - Stroking of underlined or strike through text is not supported in versions of Android prior to 4.2
    - Android 4.3 bug that breaks the <clipPath> feature when using renderToPicture()
    - SVGImageView has documented issues in Android Studio
    - 复杂图形渲染和长度限制
- 例子项目：
https://github.com/bmarrdev/CountryRank

svg-android：

- svg渲染到canvas上
- 已经废弃，最后更新2012年

- 网址: https://github.com/pents90/svg-android/tree/master/svgandroid

svg-android-2：

- 修改了svg-android的一些bug

- svg-android的fork版本最后更新在2014,
- 网址: http://code.google.com/p/svg-android-2/

TPSVG Android SVG Library

- 速度更快，提供了callback 可以操纵image的节点
- 2013年最后更新

android-pathview:

- 基于androidsvg－1.2.1，在它的基础上进行了修改添加了path动画支持，看了源码，其实是在Canvas回调中获取到全部svg path路径做单独渲染，思路可以借鉴
- 最后一次更新2016年2月20日 关注961 fork197
- 网址：https://github.com/geftimov/android-pathview/commits/master

### 方案三：自定义图元＋数据＋原生绘制

优势：

- 这种方式是种一定可以实现的方式，也是一种常规解决方法，全部问题都可控

缺点：

- 只针对具体问题，换个项目都要重新编写图元，重用性基本没有
- 数据到屏幕的点转化是个问题
- 是否要添加手势操作，手势放大缩小后整个图的渲染细节处理
- 可能隐含有未知技术问题

###  总结：

- 首先尝试VectorDrawable，并结合pathview思路去解决路径动态控制问题
- 其次尝试基于AndroidSVG项目的 pathview思想
- 解决问题前两种都失败情况下采用第三种


