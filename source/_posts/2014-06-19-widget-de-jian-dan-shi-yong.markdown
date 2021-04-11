---
layout: post
title: "Widget 的简单使用"
date: 2014-06-19 14:54:03 +0800
comments: true
categories: Android
---
项目中用到了桌面小部件也就是widget，这里做下简单使用的总结
最终实现的效果，如图

![](http://www.pffair.com/images/15.png)

点击部件按钮后进入相应activity，如图

![](http://www.pffair.com/images/16.png)

<!--more-->

####代码实现：

第一步，创建一个AppWidgetProvider的子类，重写onUpdate方法

```java

@Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager,
            int[] appWidgetIds) {
        for (int i = 0; i < appWidgetIds.length; i++) {
            Intent intent = new Intent(context, TestActivity.class);
          intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, 1);//参数传递
            PendingIntent pendingIntent = PendingIntent.getActivity(context, appWidgetIds[i],
                    intent, PendingIntent.FLAG_UPDATE_CURRENT);
            RemoteViews remoteViews = new RemoteViews(context.getPackageName(),R.layout.main);
            remoteViews.setOnClickPendingIntent(R.id.btn, pendingIntent);
            appWidgetManager.updateAppWidget(appWidgetIds[i], remoteViews);
        }
        super.onUpdate(context, appWidgetManager, appWidgetIds);
    }
```

####注意：

```
PendingIntent pendingIntent = 	PendingIntent.getActivity(context, appWidgetIds[i],
intent, PendingIntent.FLAG_UPDATE_CURRENT);
```
getActivty方法的第二个参数是指明每个Intent是否是新的Intent、最后一个参数指明是否传参数，最初没注意这个方法两个地方都传的0使得参数传递出了问题。最后一个参数如果是0那么不会传参数；如果最后一个设置为FLAG_UPDATE_CURRENT，第二个参数如果为0那么每次都是同一个intent，有多个widget时后面的widget intent会覆盖前面的。（比如第一个拖动来的widget传递了参数1，第二个拖动来的widget传递的参数是2，后面的widget会覆盖前面的，这时候点击前面的widget会发现参数也是2）

第二步，定义AndroidManifest.xml中定义receiver

```xml

<receiver
            android:name="MainProvider2"
            android:label="widget2" >
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/widget_provider2" />
        </receiver>
```

第三步，定义widget 的xml。在res下创建xml目录，在该目录下创建widget_provider.xml

```xml

<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:initialLayout="@layout/main"
    android:minHeight="50dip"
    android:minWidth="98dip"
    android:updatePeriodMillis="10000" />
```

####扩展，多widget情况
	
	按之前流程再多定义一个provider

####项目参考：
https://github.com/pangff/WidgetDemo