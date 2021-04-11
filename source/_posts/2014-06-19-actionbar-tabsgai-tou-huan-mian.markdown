---
layout: post
title: "ActionBar Tabs改头换面"
date: 2014-06-19 15:02:03 +0800
comments: true
categories: Android
---
先看效果

![修改前](http://www.pffair.com/images/17.png)

修改后

![修改前](http://www.pffair.com/images/18.png)

第一眼看上去上面的导航不像个ActionBar的Tabs，但是这个的确是用ActionBar实现的
<!--more-->

看下具体的实现，实现方式主要是覆盖ActionBar的原有style，下面是需要覆盖的样式

```xml

 <style name="AppTheme" parent="AppBaseTheme">
     <item name="android:windowContentOverlay">@null</item>
     <item name="android:actionBarStyle">@style/MyActionBar</item>
     <item name="android:actionBarTabBarStyle">@style/MyActionBarTabBarStyle</item> 
     <item name="android:actionBarTabStyle">@style/MyActionBarTabStyle</item> 
     <item name="android:actionBarTabTextStyle">@style/Widget.Holo.ActionBar.TabText</item>
 </style>
```

首先来设置ActionBar的背景

```xml

<style name="MyActionBar" parent="@android:style/Widget.Holo.ActionBar">
        <item name="android:windowActionBarOverlay">true</item>
         <item name="android:height">80px</item>
        <item name="android:background">@drawable/actionbar_bg</item>
        <item name="android:backgroundStacked">@drawable/actionbar_bg</item>
        <item name="android:backgroundSplit">@drawable/actionbar_bg</item>
    </style>
```

其次来去掉ActionBar下面的阴影，使得整体页面的背景可以和ActionBar进行拼接


```xml

<item name="android:windowContentOverlay">@null</item>
```

接下来去掉Tabs直线的分隔竖线

```xml

<style name="MyActionBarTabBarStyle" parent="@android:style/Widget.Holo.ActionBar.TabBar">  
       <item name="android:divider">?android:attr/actionBarDivider</item>
       <item name="android:showDividers">none</item>
       <item name="android:paddingLeft">80px</item>
       <item name="android:dividerPadding">24dip</item>
   </style>
```

接下来修改Tabs选中后下面的横条

```xml

<style name="MyActionBarTabStyle" parent="@android:style/Widget.Holo.ActionBar.TabView">  
        <item name="android:paddingTop">35px</item>
        <item name="android:background">@drawable/antionbar_tab</item>
        <item name="android:paddingStart">16dip</item>
        <item name="android:paddingEnd">16dip</item>
    </style>
```

最后调整Tabs上文字颜色和大小

```xml
<style name="Widget.Holo.ActionBar.TabText" parent="@android:style/Widget.ActionBar.TabText">
      <item name="android:textColor">@android:color/white</item>
      <item name="android:textSize">24px</item>
      <item name="android:textStyle">bold</item>
      <item name="android:textAllCaps">true</item>
      <item name="android:ellipsize">marquee</item>
      <item name="android:maxLines">1</item>
  </style>

```

