---
layout: post
title: "Android View自定义专题一 (view的绘制)"
date: 2014-06-19 08:58:44 +0800
comments: true
categories: android
---

项目中经常会有一些特殊的需求，而这些需求往往skd中的原生view控件不能或很难满足，这时候就需要我们自定义一些view来满足需求。
下面来介绍下如何进行view自定义(绘制部分)
 <!--more-->
####一、首先要了解view的绘制机制（onMeasure－onLayout－onDraw）

   * onMeasure是来衡量自身和其子view大小的，从父级开始每一级的onMeasure完成后会将自身的宽高信息纪录下来（通过getMeasuredHeight、getMeasuredWidth获取）
   * onLayout是来确定view以及其子view的位置的，从父级别开始每一级确定位置纪录下来（通过getLeft、getTop等获取）
   * onDraw就比较好理解了，它是用来绘制视图的

如下图，为多层view架构下onMeasure－onLayout的调用方式

![onMeasure－onLayout的调用方式](http://www.pffair.com/images/1.png)

我们用三个层叠view为例，其调用顺序为:
		
   * 调用第一级的(onMeasure)---第二级的(onMeasure)---第三级的(onMeasure)---第三级(onMeasure返回)---第二级(onMeasure返回)---第一级(onMeasure返回)
   * 之后调用第一级的(onLayout)---第二级(onLayout)---第三级(onLayout)---第三级的(onLayout返回)---第二级(onLayout返回)---第一级(onLayout返回)
   * 最后调用第一级的(onDraw)---第二级(onDraw)---第三级(onDraw)---第三级的(onDraw返回)---第二级(onDraw返回)---第一级(onDraw返回)［注意如果view是ViewGroup那么应该是dispatchDraw］

值得注意的是MeasureSpecs，它是父级别view测量该子view时的标尺。有三种模式(UNSPECIFIED、EXACTLY、AT_MOST)

   * UNSPECIFIED：通过xml布局不会出现，一般是用来作试探性的测量，比如设置高为UNSPECIFIED、宽为固定的240dp去衡量子视图，子视图可以根据固定的240宽去计算需要多高的空间
   * EXACTLY：xml中设置为match_parent或具体的数值时会使用，父级别来限制
   * AT_MOST：xml中设置为wrap_content时会使用，不要求父级别来加以限制

通过事例程序可以从日志中获取以上信息，参考事例:<https://github.com/pangff/customview>
 
####二、我们模仿官方的LableView来进行一个简单view(不涉及ViewGroup)的绘制－－－不换行的textview
首先继承View添加构造方法

```java

public class MyView extends View {
 
 private Paint mTextPaint;

 private String mText;

 private int mAscent;

  
 public MyView(Context context) {

 super(context);

 initLabelView();

 }

 public MyView(Context context, AttributeSet attrs) {

 super(context, attrs);

 initLabelView();

 }
}
```

其次重写onMeasure

```java

@Override
protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        //作为叶子节点的view必须setMeasureDimesion否则抛异常
        //（或者调用super.onMeasure(w,h);但是对于子view调用super.onMeasure(w,h)无意义）
    setMeasuredDimension(measureWidth(widthMeasureSpec),measureHeight(heightMeasureSpec));
}
/**
* 计算view的宽度
* @param measureSpec
* @return
 */
private int measureWidth(int measureSpec) {
    int result = 0;
    int specMode = MeasureSpec.getMode(measureSpec);
    int specSize = MeasureSpec.getSize(measureSpec);
 
if (specMode == MeasureSpec.EXACTLY) {//match_parent或具体数值,直接使用
 result = specSize;
} else {//否则自己计算
 // 计算文字宽度
 result = (int) mTextPaint.measureText(mText) + getPaddingLeft()+ getPaddingRight();
 if (specMode == MeasureSpec.AT_MOST) {//wrap_content
     //取specSize和计算出的文字宽度最小数值，如果result大于specSize说明文字超出了view宽度范围
     result = Math.min(result, specSize);
 }
}
return result;
}


/**
* 计算view的高度
* @param measureSpec
* @return
 */
private int measureHeight(int measureSpec) {
    int result = 0;
    int specMode = MeasureSpec.getMode(measureSpec);
    int specSize = MeasureSpec.getSize(measureSpec);
    mAscent = (int) mTextPaint.ascent();
    if (specMode == MeasureSpec.EXACTLY) {//match_parent或具体数值,直接使用
        result = specSize;
    } else {//否则自己计算
        // 计算文字高度
        result = (int) (-mAscent + mTextPaint.descent()) + getPaddingTop() + getPaddingBottom();
        if (specMode == MeasureSpec.AT_MOST) {
            //取specSize和计算出的文字高度最小数值，如果result大于specSize说明文字超出了view高度范围
            result = Math.min(result, specSize);
        }
    }
    return result;
}
```

```java

最后绘制

/**
* 绘制视图
*/
@Override
protected void onDraw(Canvas canvas) {
    super.onDraw(canvas);
    canvas.drawText(mText, getPaddingLeft(), getPaddingTop() - mAscent,mTextPaint);
});
}
```