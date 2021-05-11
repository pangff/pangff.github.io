---
layout: post
title: "Rajawali入门"
date: 2014-06-19 16:05:10 +0800
comments: true
categories: Android
---
rajawali是Android OpenGL ES 2.0/3.0引擎。https://github.com/MasDennis/Rajawali

<!--more-->

####正确的加载rajawali

首先要导入rajawali库

然后，可以创建自己项目（最简单的helloworld），注意，一定要sdk17，也就是android 4.2，因为rajawali最新版本使用了该版本下的dreamservice（DayDream），当然，你也可以切换到v0.9版本，这样兼容到android 2.3。

修改继承关系，Activity改为RajawaliActivity。这时候就可以测试了，应该没有报错的跑起来，虽然和以前的hello world显示是一样的。

####把Render跑起来，啥也不画

创建一个Render类，要继承RajawaliRenderer，继承就行了，啥也不用干（得写个构造方法）。

然后，在m0创建的activity中：

```java

private MyRenderer myRenderer;

 /**
  * Called when the activity is first created.
  */
 @Override
 public void onCreate(Bundle savedInstanceState) {
     super.onCreate(savedInstanceState);
	 myRenderer=new MyRenderer(this);
	 myRenderer.setSurfaceView(mSurfaceView);
     super.setRenderer(myRenderer);
 }
```

再次执行，会发现啥也没显示，但是不报错，ok，就是这个效果。

####画个球

如果参照当前官网turorial01，肯定是不行了，首先是已经没有DiffuseMaterial类了。另外，原文给的代码链接已经失效。必须找到

	https://github.com/MasDennis/RajawaliExamples 

从这里找到需要的图和代码。

不过当前Examples项目使用的是Fragment，我转到自己简单的代码中，发现光效是无效的。索性在m2中暂时不加入光效。（光效是出不来的了，我测试了Examples项目，问题是一样的）。


####给球加上灯光

参照最新Examples项目的DirectionalLight示例，给地球加上了灯光。主要是这句话：

     material.setDiffuseMethod(new DiffuseMethod.Lambert());


####凹凸纹理贴图

凹凸纹理，需要两张图：


   * 1张颜色纹理图（就是只有颜色，不包含阴影和凹凸信息），也叫做漫射图（通过漫反射看到的效果）
   * 1张凹凸纹理图，一般是法线纹理，特点是1张发蓝色的图（它本身不代表颜色，只是借用RGB表示XYZ法线方向）

贴图本身不复杂（其实复杂，复杂的部分引擎代劳了，就是怎么计算像素点最终的颜色值，要综合颜色图以及法线方向等等因素）。

代码上只是增加2个纹理即可：

     material.addTexture(new Texture("surfaceTexture",surface));
     material.addTexture(new NormalMapTexture("normalTexture", normal));

源代码在这里：

	https://github.com/MarshalW/Planets/tree/m4 