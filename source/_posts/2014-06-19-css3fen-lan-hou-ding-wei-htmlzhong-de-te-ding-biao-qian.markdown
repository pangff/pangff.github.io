---
layout: post
title: "css3分栏后定位html中的特定标签"
date: 2014-06-19 10:39:29 +0800
comments: true
categories: js
---
在android项目中遇到这样一个问题，使用webview加载通过css3 -webkit-column 分栏过的html页面，要获取当前页面中的img。由于要适配不同屏幕不能确定 -webkit-column每一页的分栏位置。如下图所示，要在这两个被分栏后的每一个页面中找到其中的图片。

![](http://www.pffair.com/images/4.png)

<!--more-->
思路：采用遍历页面命中img标签方式。如下图按30px为纵向间隔，页面宽度的1/4为横向间隔从上到下从左到右开始遍历命中标签。

![](http://www.pffair.com/images/5.png)

注意：（横向和纵向间隔按情况来定，因为例子中图片高度均小于30px宽度均小页面的1/4，所以按这个来定。当然因为要考虑到效率问题不能太小间隔，适宜最好）
命中算法：

```javascript

 var line = 1;
   var imageArray = new Array();//存储遍历得到的img
   /**
    * 递归遍历页面
    */
   function getImg(top){
	  //关键方法，返回指定坐标上的element
       var e = document.elementFromPoint(document.body.clientWidth*line/4, top);
       if(e!=null&&e.nodeName == 'IMG'){//如果时img标签
    	    //遍历时一个图片很可能被命中多次，要去掉重复的（这里通过id，可以通过图片位置）
    	   	if(!hasImage($(e).attr("id"))){
    	   		imageArray.push(e);
    	   	}
       }
       if(document.body.clientHeight>top){//如果小于当前页面高度，高度＋30 递归遍历
    		  return getImg(top + 30);
       }else{
    	   	  if(line==3){//全部3次从上到下遍历完成
    	   		return true;
    	   	  }else{//遍历完一次就让横向间隔增加页面宽度的1/4。然后从最上面top＝0开始下次遍历
    	   		line++;
    	   		return getImg(0);
    	   	  }
       }
   }
```
调用方式：

```javascript

if(getImg(0)==true){
	 returnPositionInfo();
}
```