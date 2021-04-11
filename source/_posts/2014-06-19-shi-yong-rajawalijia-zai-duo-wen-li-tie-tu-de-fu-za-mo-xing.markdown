---
layout: post
title: "使用Rajawali加载多纹理贴图的复杂模型"
date: 2014-06-19 16:13:50 +0800
comments: true
categories: Android 3D
---
在上篇笔记中介绍了使用Rajawali加载外部模型的步骤以及注意事项，但是上篇中只加载了一个简单的少纹理贴图的模型，下面通过一个复杂模型的加载来说明多纹理贴图模型加载注意事项。

<!--more-->

一、下载模型<http://tf3dm.com/3d-model/beautiful-girl-57398.html>

二、根据上篇笔记中的方法修改下载后的.obj .mtl文件（修改名称、obj中mtl的指向、mtl的纹理名称） 以及Texture目录中的dds纹理贴图（dds需要通过XnView导出成psd，用photoshop打开后导出成png图片）

三、新建项目（同上篇笔记）导出后文件放入项目指定目录，如图

![](http://www.pffair.com/images/25.png)
![](http://www.pffair.com/images/27.png)

四、 项目中导入模型换为bg_obj模型，此时运行项目会提示 NoSuchElementException的异常，这是因为bg_mtl文件中存在空的token，把该文件中空值的token删除，并把Ks 0.9 0.9 0.9 改为Ks 0 0 0。


五、再运行程序发现程序不出错了，模型显示了，但是没有贴图。打开bg_obj文件，将里面g开头的token 都改成 o。

六、再次运行可以成功贴图，但是女孩的一只手没有贴出来。打开bg_obj文件，仔细观察会发现这个文件是 按顶点坐标、使用纹理排列的。其中有hand01和hand。hand01对应使用的纹理指明了为usemtl Material__30，而hand对应的纹理却没指明，在最后一段# 124 normals 下面加上 # 124 normals。再次运行程序，成功了！

七、项目参考https://github.com/pangff/myRajawali/tree/beautiful_girl 

运行结果（注意调整模型方向）

![](http://www.pffair.com/images/26.png)
