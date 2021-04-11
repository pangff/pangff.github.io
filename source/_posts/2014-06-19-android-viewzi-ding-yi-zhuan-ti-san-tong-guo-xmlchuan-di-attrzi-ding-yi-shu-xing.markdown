---
layout: post
title: "Android View自定义专题三(通过xml传递attr自定义属性)"
date: 2014-06-19 09:32:12 +0800
comments: true
categories: Android
---


书接Android View自定义专题二（View滑动的实现），上一回我们实现了view的平滑滚动，这一次为了方便起见我们将字体和字体颜色的属性通过xml配置传递过来。
<!--more-->
####一、在values/attrs.xml中定义自己需要的属性

```java

<?xml version="1.0" encoding="utf-8"?>
<resources]] >
    <declare-styleable name="MyView"]] >
        <!-- 字体颜色 -->
        <attr name="textColor" format="reference|color" />
        <!-- 字体大小 -->
        <attr name="textSize" format="dimension" />
    </declare-styleable]] >
</resources> 
```

####二、在自定义view构造方法中接收属性

```java

public MyView(Context context, AttributeSet attrs) {
    super(context, attrs);
    initLabelView();
    this.flinger = new Flinger(context);
    final ViewConfiguration configuration = ViewConfiguration.get(context);
    this.minimumVelocity = configuration.getScaledMinimumFlingVelocity();
    this.maximumVelocity = configuration.getScaledMaximumFlingVelocity();
    /**
     * 获取自定义配置资源
     */
    TypedArray a = context.obtainStyledAttributes(attrs, R.styleable.MyView);
    textColor = a.getColor(R.styleable.MyView_textColor, Color.BLACK);
    textSize = a.getDimension(R.styleable.MyView_textSize, 15);
    mTextPaint.setTextSize(textSize);
    mTextPaint.setColor(textColor);
    //注意回收
    if(a!=null){
        a.recycle();
    }
}
```
####三、使用方法

```java

<com.pangff.demoview.MyView
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/text"
    app:textColor="#123456"
    app:textSize="30sp"
    android:layout_centerInParent="true"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content" />
```

####四、设置属性前后效果


设置属性前后对比    

![设置前](http://www.pffair.com/images/3.png)
![设置后](http://www.pffair.com/images/2.png)
 

####参考代码

https://github.com/pangff/DemoView/tree/v3
