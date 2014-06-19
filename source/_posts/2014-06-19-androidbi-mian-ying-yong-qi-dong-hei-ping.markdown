---
layout: post
title: "Android避免应用启动黑屏"
date: 2014-06-19 10:34:55 +0800
comments: true
categories: android
---
问题：
Android如果不做特殊处理启动时都会先出现一个黑(或白，这个要根据应用theme决定)屏，这个闪屏的出现是因为Activity初始化需要时间(即使你的Activity简单到只渲染一个hello word)。为了增强体验如何去掉它呢？
<!--more-->
解决办法：
一般而言我们的应用在启动时都会有一个加载页作为应用启动的提示。我们要做的就是把加载页从layout的xml中拿出来做为启动Activity的theme使用。
具体步骤:
在style.xml中添加自定义的style，代码如下

添加自定义style

```java

<stylename="Theme.Start"parent="android:Theme"]] > 
  <itemname="android:windowBackground">@drawable/splash</item> 
  <itemname="android:windowNoTitle">true</item> 
</style]] > 
```

在AndroidManifest.xml文件中的启动Activity中将其以theme引入

作为theme加入到启动activity中


```java

<activity
   android:name="com.jhss.youguu.LoadImageActivity"
   android:launchMode="singleTop"
   android:theme="@style/Theme.Start"
   android:screenOrientation="portrait"
   android:windowSoftInputMode="adjustPan"]] > 
      <intent-filter]] > 
         <actionandroid:name="android.intent.action.MAIN"/>
         <categoryandroid:name="android.intent.category.LAUNCHER"/>
     </intent-filter]] > 
</activity]] >
``` 

最后，将启动Activity的布局xml背景去掉（如果不去掉一方面会背景冗余，另一方面作为theme的背景和作为layout的背景不能完全重叠，非纯色背景页面会有跳动感）
