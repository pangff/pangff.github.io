---
layout: post
title: "Textview文字末尾拼接带本地图片背景文字"
date: 2014-07-10 18:20:53 +0800
comments: true
categories: android
---

做androidk开发的盆友们都知道可以通过ColorSpan、Html.from("html标签")的方式为TextView中的部分文字改变颜色，或者改变背景。但是如果要给TextView文字末尾拼接带本地图片背景的文字改如何实现呢？（比如添加一个带圆角背景的更多文字）
<!--more-->

###思路：
 * 查看TextView是否可以在中文中插入图片
 * 如果可以，那么将文字内容和背景图片合并成一个图片
 * 将合成图片插入正文

###实现：


####TextView中插入图片,

```java
textView = (TextView) findViewById(R.id.text);

ImageGetter imageGetter = new ImageGetter() {
	@Override
	public Drawable getDrawable(String source) {
		int resId = Integer.parseInt(source);
		Drawable drawable = MainActivity.this.getResources()
				.getDrawable(resId);
		drawable.setBounds(0, 0, drawable.getIntrinsicWidth(),
				drawable.getIntrinsicHeight());
		return drawable;
	}
};

textView.setText(Html.fromHtml("我要添加一个<img src=\""+R.drawable.ic_launcher+"\">，看到了吗?", imageGetter, null));
```

![效果图](http://www.pffair.com/images/28.png)



####文字和背景合并插入正文中

自定义TextDrawable，将文字内容传入，用canvas将文字和绘制的圆角矩形合并（本地图片同理）

```java

@Override
public void draw(Canvas canvas) {
		paint.setColor(Color.RED);
		rectF.set(padding,  -height-linsSpaceExtra, padding+rectWidth, -linsSpaceExtra);
		canvas.drawRoundRect(rectF, height/2, height/2, paint);
		//canvas.drawRect(padding,  -height-linsSpaceExtra, padding+rectWidth, -linsSpaceExtra, paint);
		int baseline = (int) (rectF.top + (rectF.bottom - rectF.top - paint.getFontMetrics().bottom + paint.getFontMetrics().top) / 2 - paint.getFontMetrics().top)-2;
		paint.setColor(Color.WHITE);
    canvas.drawText(text, rectF.centerX(),  baseline, paint);
}
```

调用
```java

textView = (TextView) findViewById(R.id.text);
ImageGetter imageGetter = new ImageGetter() {
	@Override
	public Drawable getDrawable(String source) {
		int height = (int) Math.ceil(textView.getPaint().getFontMetrics().descent - textView.getPaint().getFontMetrics().top) + 2;
		Drawable drawable = new TextDrawable(source,height,Util.DipToPixels(MainActivity.this,5),Util.DipToPixels(MainActivity.this,13));  
		drawable.setBounds(0, 0, drawable.getIntrinsicWidth(),
				drawable.getIntrinsicHeight());
		return drawable;
	}
};
textView.setText(Html.fromHtml("在上篇笔记中介绍了使用Rajawali加载外部模型的步骤以及注意事项，但是上篇中只加载了一个简单的少纹理贴图的模型，下面通过一个复杂模型的加
```
效果，为了看出更多随文字变化，这里传两个

![效果图](http://www.pffair.com/images/29.png)

###参考项目
	https://github.com/pangff/textview_inline_drawable
