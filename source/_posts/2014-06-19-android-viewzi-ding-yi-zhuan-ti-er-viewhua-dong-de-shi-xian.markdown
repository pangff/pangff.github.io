---
layout: post
title: "Android View自定义专题二(View滑动的实现)"
date: 2014-06-19 09:20:05 +0800
comments: true
categories: android
---
接着上一篇Android View自定义专题一 (view的绘制)，我们接下来要在上一篇的基础上为不能换行的textview加上横向滚动条，这里只说x方向滑动（y方向类似）。
<!--more-->
####实现scroll的思路：
重写onTouchEvent，

   * ACTION_DOWN纪录按下x位置，
   * ACTION_MOVE用当按下x减去当前x获得需要滑动距离调用scrollBy滑动
   * 在ACTION_UP抬起时需要根据当前的速度来惯性的再滑动一段距离，所以需要纪录手指抬起的速度，和需要滑动的最大距离

####具体实现：
一、在昨天代码基础上重写onTouchEvent并在ACTION_DOWN纪录手指按下的x

```java

@Override
publicbooleanonTouchEvent(MotionEvent event) {
    switch(event.getAction()) {
        caseMotionEvent.ACTION_DOWN:
            downX = (int) event.getX();//纪录按下位置
            break;
        caseMotionEvent.ACTION_MOVE:
            break;
        caseMotionEvent.ACTION_UP:
            break;
        default:
            break;
    }
    returntrue;
}
```

二、在ACTION_MOVE中获取移动距离，并调用滑动响应距离


```java

@Override
publicbooleanonTouchEvent(MotionEvent event) {
    switch(event.getAction()) {
        caseMotionEvent.ACTION_DOWN:
            downX = (int) event.getX();
            break;
        caseMotionEvent.ACTION_MOVE:
            intdx = (int) (downX - event.getX());
            scrollBy(dx,0);
            break;
        caseMotionEvent.ACTION_UP:
            break;
        default:
            break;
    }
    returntrue;
}
```

三、在滑动时要根据滑动边界来限制滑动距离（最小scrollX为0即初始最左位置，最大scrollX＝内容最大宽度－view宽度，即可滑动最大距离）

* 获取view最大宽度和内容最大宽度

```java

 /**
 * 计算view的宽度
 * @param measureSpec
 * @return
 */
privateintmeasureWidth(intmeasureSpec) {
    intresult =0;
    intspecMode = MeasureSpec.getMode(measureSpec);
    intspecSize = MeasureSpec.getSize(measureSpec);
    viewWidth = specSize;//视图view宽度
    if(specMode == MeasureSpec.EXACTLY) {// match_parent或具体数值,直接使用
        result = specSize;
    }else{// 否则自己计算
        // 计算文字宽度
        result = (int) mTextPaint.measureText(mText) + getPaddingLeft()+ getPaddingRight();
        maxWidth = result;//内容宽度
        if(specMode == MeasureSpec.AT_MOST) {// wrap_content
            // 取specSize和计算出的文字宽度最小数值，如果result大于specSize说明文字超出了view宽度范围
            result = Math.min(result, specSize);
        }
    }
    returnresult;
}
```

* 根据最小最大滑动距离限制scrollBy的距离

```java

/**
 * 获取最大的滑动距离
 * @return
 */
publicintgetMaxScrollX() {
    if(maxWidth - viewWidth >0) {
        return(maxWidth - viewWidth);
    }else{
        return0;
    }
}
```

* 根据两个最大宽度获取可滑动最大距离

```java

/**
 * 对超出范围进行判断
 */
publicvoidscrollBy(intdx,intdy) {
    if(getScrollX() + dx > getMaxScrollX()) {//超出最大范围
        super.scrollBy(getMaxScrollX() - getScrollX(),0);
    }elseif(getScrollX() + dx <0) {//超出最小范围
        super.scrollBy(-getScrollX(),0);
    }else{
        super.scrollBy(dx,0);
    }
}
```

四、根据滑动速度进行ACTION_UP的惯性滑动

* 初始化系统最大最小滑动速度以及滑动线程

```java

publicMyView(Context context, AttributeSet attrs) {
    super(context, attrs);
    initLabelView();
    this.flinger =newFlinger(context);
    finalViewConfiguration configuration = ViewConfiguration.get(context);
    this.minimumVelocity = configuration.getScaledMinimumFlingVelocity();
    this.maximumVelocity = configuration.getScaledMaximumFlingVelocity();
} 
```

* onTouchEvent进行相关配置并启动滑动线程

```java

@Override
publicbooleanonTouchEvent(MotionEvent event) {
    if(velocityTracker ==null) {
        velocityTracker = VelocityTracker.obtain();// 初始化速度追踪器
    }
    velocityTracker.addMovement(event);// 添加事件到速度追踪器中
    switch(event.getAction()) {
        caseMotionEvent.ACTION_DOWN:
            downX = (int) event.getX();
            if(!flinger.isFinished()) {// 如果正在滚动马上停止
                flinger.forceFinished();
            }
            break;
        caseMotionEvent.ACTION_MOVE:
            intdx = (int) (downX - event.getX());
            scrollBy(dx,0);
            break;
        caseMotionEvent.ACTION_UP:
            finalVelocityTracker velocityTracker =this.velocityTracker;
            velocityTracker.computeCurrentVelocity(1000, maximumVelocity);//计算当前速度(按1秒为单位)
            intvelocityX = (int) velocityTracker.getXVelocity();//获取x方向速度
            intvelocityY = (int) velocityTracker.getYVelocity();//获取y方向速度
            if(Math.abs(velocityX) > minimumVelocity|| Math.abs(velocityY) > minimumVelocity) {
                flinger.start(getScrollX(), getScrollY(), velocityX,0,getMaxScrollX(),0);
            }else{// 记得回收
                if(this.velocityTracker !=null) {
                    this.velocityTracker.recycle();
                    this.velocityTracker =null;
                }
            }
            break;
        default:
            break;
    }
    returntrue;
}
```

* 滚动线程

```java

/**
 * 控制滚动的线程
 * @author pangff
 */
privateclassFlingerimplementsRunnable {

privatefinalScroller scroller;
privateintlastX =0;
privateintlastY =0;
Flinger(Context context) {
scroller =newScroller(context);
}

voidstart(intinitX,intinitY,intinitialVelocityX,intinitialVelocityY,intmaxX,intmaxY) {
scroller.fling(initX, initY, initialVelocityX, initialVelocityY,0,maxX,0, maxY);
lastX = initX;
lastY = initY;
post(this);
}

publicvoidrun() {
if(scroller.isFinished()) {
return;
}
booleanmore = scroller.computeScrollOffset();//获取是否需要继续滑动
intx = scroller.getCurrX();//获取滑动中的当前scrollX
inty = scroller.getCurrY();//获取滑动中的当前scrollY
intdiffX = lastX - x;//取增量
intdiffY = lastY - y;//取增量
if(diffX !=0|| diffY !=0) {
scrollBy(diffX, diffY);
lastX = x;//纪录当前位置
lastY = y;//纪录当前位置
}
if(more) {//如果还需要继续滑动，再次执行
post(this);
}
}

booleanisFinished() {
returnscroller.isFinished();
}

voidforceFinished() {
if(!scroller.isFinished()) {
scroller.forceFinished(true);
}
}
}
```

####参考代码

<https://github.com/pangff/DemoView/tree/v2>