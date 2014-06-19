---
layout: post
title: "使用Rajawali加载外部模型及其纹理贴图的步骤"
date: 2014-06-19 16:10:14 +0800
comments: true
categories: android 3D
---
一、下载要加载的模型（我下载的是一个比较简单模型，地址<http://tf3dm.com/3d-model/doomsday-52515.html>）
<!--more-->

二、用blender导入模型，然后导出为obj。这里有几个需要注意的地方

具体可以参考
	
	https://github.com/MasDennis/Rajawali/wiki/Tutorial-17-Importing-.Obj-Files


 导出时要勾选以下选项： 

   * Apply Modifiers
   * Include Normals
   * Include UVs
   * Write Materials (if applicable)
   * Triangulate Faces
   * Objects as OBJ Objects     

  导出后的文件需要重命名： 

   * doomsday villain103.obj > villain_obj
   * doomsday villain103.mtl > villain_mtl

导出后的图片重命名： 

   * CHRNPCICOVIL103_DIFFUSE.tga > villain_d.png
   * CHRNPCICOVIL103_NORMAL.tga > villain_n.png

 
 修改相关路径： 

   * 打开villain_obj修改： mtllib doomsday villain103.mtl >  mtllib villain_mtl
   * 打开villain_mtl 修改贴图的路径: CHRNPCICOVIL103_NORMAL.tga > villain_n.png  CHRNPCICOVIL103_DIFFUSE.tga >  villain_d.png


三、一切准备就绪，通过android rajawali项目导入模型并显示

   * 新建项目myRajawali，导入rajawali库（参考之前笔记）
   * 将villain_d.png、 villain_n.png放在drawable-nodpi目录下；将villain_obj、villain_mtl放到layout/raw目录下
   * 编写代码渲染
   * 项目参考：https://github.com/pangff/myRajawali/tree/simple_ugly

注意：如果贴图失败，需要对图片进行处理：


   * download XnView
   * open the .png file with XnView
   * save the files as a .psd file
   * open the .psd file in Photoshop
   * export the file to .png or .jpg

最终效果，如图

![](http://www.pffair.com/images/24.png)