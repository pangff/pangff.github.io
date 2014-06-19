---
layout: post
title: "富媒体1－WebView实现的图文混排"
date: 2014-06-19 15:14:02 +0800
comments: true
categories: android
---
android设备繁多分辨率各种各样，对于app的屏幕适配本身已经是个很困难的问题，而对于不同设备的图文混排实现就更加困难了。因为传统的本地应用方式做图文混排需要对原始资源进行拆分排版在屏幕上定位，如果定制设备的话精确定位到固定坐标就可以了，但是要做多设备就不得不再重新计算排版定位了，每台设备都要重新计算这无疑将会是一个巨大的工作量。所以，我们考虑采用WebView加载html页面的方式来实现图文混排。因为html+css本身就可以做到图文混排，而且前期排版的工作量不会很大，通过css做多设备适配也相对容易。

<!--more-->

实现效果

* 采用css3分栏模式，一栏为一屏；
* 宽高适应屏幕大小；
* 横向滑动（尚未做翻页控制）

如图

![](http://www.pffair.com/images/19.png)
![](http://www.pffair.com/images/20.png)

实现思路：

* 通过webview加载简单混排后的html，通过css使得可以在设备上正常显示并体验良好。
* 通过第一步确定固定的html页面格式，也就是模版
* 服务器端通过上传原始数据，生成客户端需要的指定模版数据
* 客户端动态加载服务器端的指定模板数据

具体实现：

1、使用WebView加载一个简单的hmtl页面
在assets目录下创建book.html文件，引入jquery。

```html

<html>
<head>
    <title>天蝎座</title>
    <meta charset="utf-8">
    <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0,width=device-width,user-scalable=no">
    <script src="jquery-1.9.1.min.js"></script>
    <link href="book.css" rel="stylesheet" type="text/css">
</head>
<body >
<div id="content">
测试
</div>
</body>
</html>
```

WebView加载book.html

```java

webView.loadUrl("file:///android_asset/book.html");
```

2、编写html实现图文混排，用css3分栏并控制内容适应屏幕宽高
填写html内容

```html

<html>
<head>
    <title>天蝎座</title>
    <meta charset="utf-8">
    <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0,width=device-width,user-scalable=no">
    <script src="jquery-1.9.1.min.js"></script>
    <link href="book.css" rel="stylesheet" type="text/css">
</head>
<body >
<div id="content">
<article id="article">
	<header>天蝎座</header>
	<img style="float:right" src="images/1.jpg" />
	<p stye="float:left;text-indent:2em;">天蝎座，黄道十二宫之一。位于南半球，在西面的天秤座与东面的人马座之间，是一个接近银河中心的大星座。
		阳历10月24日～11月22日（小雪）期间出生的人为天蝎座。Scorpio是天蝎座的英文也是希腊文，十二星座只有三个星座英文和希腊文一样，天蝎座即是其中之一。
	</p>
	<header>历史起源</header>
	<p>黄道十二星座中最显著的星座。中心位置：赤经16时40分，赤 天蝎
		纬－36度。夏季出现在南方天空，蝎尾指向东南，在人马、天秤等星座之间。α星（心宿二）是红色的1等星。疏散星团M6和M7肉眼均可见。座内有亮于4等的星22颗。
	</p>
	<p>天蝎宫 第八宫。黄经从210度到240度。每年10月23日前后太阳到这一宫。那时的节气是霜降。 属性 ：水相星座
		守护星：冥王星，火星 宫位 ：第八宫 象征 ：蝎子 阴阳性 ：阴性 三方态 ：固定宫 守护神
		：希腊┈哈迪斯（Hades），罗马┈普鲁特（Pluto）</p>
	<p>9月13日，澳大利亚墨尔本市政厅放映了世界上最早的配乐纪录影片《基督教的士兵》。这部纪录片长50分钟，由救世军巴依奥斯克普公司拍摄，为影片配乐作曲的是澳大利亚音乐家R·N·马卡诺里。</p>

	<header>相关传说</header>
	<img style="float:left" src="images/2.jpg" />
	<p stye="float:right;text-indent:2em;">许珀里翁之子赫利俄斯的儿子——巴野顿，天生美丽而性感，他自己也因此感到自负，态度总是傲慢而无礼，太过好 天蝎座在天空中的形状
		强的个性常使他无意间得罪了不少人。有一天，有个人告诉巴野顿说：“你并非太阳神的儿子！”说完大笑扬长而去，好强的巴野顿怎能吞得下这口气，于是便问自己的母亲：“我到底是不是赫利俄斯的儿子呢？”但是不管母亲如何再三保证他的确就是赫利俄斯所生，巴野顿仍然不相信他的母亲，于是说：“取笑你的人是宙斯的儿子，地位很高，如果仍然不相信，那么去问太阳神赫利俄斯自己吧！”
		赫利俄斯听了自己儿子的疑问，笑着说：“别听他们胡说，你当然是我的儿子！”
		巴野顿仍执意不信，其实他当然知道太阳神从不说慌，可是他却另有目的——要求驾驶父亲的太阳车，以证明自己就是赫利俄斯的儿子。“这怎么行？”赫利俄斯大惊，太阳是万物生息的主宰，一不小心就会酿巨祸，但拗不过巴野顿，赫利俄斯正说明着如何在一定轨道驾驶太阳车时，巴野顿心高气傲，听都没听立刻跳上了车，疾驰而去。
		结果当然很惨，地上的人们、动物、植物不是热死就是冻死，也乱了时间，弄得天错地暗，怨声载道。众神们为了遏止巴野顿，由天后希拉放出一支毒蝎，咬住了巴野顿的脚踝，而宙斯则用可怕的雷霆闪电击中了巴野顿，只见他惨叫一声堕落到地面，死了。
		人间又恢复了宁静，为了纪念那支也被闪电击毙的毒蝎，这个星座就被命名为“天蝎座”。</p>
</article>
</div>
</body>
</html>
```

WebView拦截css请求，返回分栏实现自适应的css

```java

@Override
protected void onSizeChanged(int w, int h, int oldw, int oldh) {
	super.onSizeChanged(w, h, oldw, oldh);

	dpWidth = (int) (w / scale);
	dpHeight = (int) (h / scale);

	webView.setWebViewClient(new WebViewClient() {
		@Override
		public WebResourceResponse shouldInterceptRequest(WebView view,
				String url) {
			if (url.equals("file:///android_asset/book.css")) {
				StringBuilder builder = new StringBuilder();
				builder.append("" + "        body{"
						+ "           margin:0px;" + "        }"
						+ "        #content{" + "           margin:0px;"
						+ "            width: "
						+ (dpWidth)
						+ "px;"
						+"color:#282828;"
						+ "            height:"
						+ (dpHeight - 20)
						+ "px;"

						+ "        }"
						+ "        header{\n"
						+"font-family:adobeFont;"
						+ "           font-size: 40px;\n"
						+ "        }"
						+ "        article header{"
						+ "            padding:0px;"
						+ "            margin:0px 50px 0px 50px;"
						+ "        }"
						+ "        img{\n"
						+ "            max-width: "
						+ (dpWidth - 110)
						+ "px;\n"
						+"box-shadow: 3px 3px 3px #787878;"
						+ "        }"
						+ "        article {"
						+ "            "
						+ // margin: 4px 5px 4px 5px;
						"        }"
						+ "        article{"
						+"line-height:200%;"
						+ "            -webkit-column-width:"
						+ dpWidth
						+ "px;"

						+ "            -webkit-column-gap: 10px;"
						+ "            height:"
						+ (dpHeight - 20 - 40)
						+ "px;"
						+"font-family:dqFont;"
						+"             font-size:25px;"
						+ "            padding: 0px;"
						+"margin-top:40px;"
						+ "        }"
						+ "        article *{"
						+ "            padding:5px;"
						+ "            margin:40px 50px 40px 50px;"
						+ "        }"
						+ "        article p{"
						+ "            padding:0px;"
						+ "            margin:15px 50px 15px 50px;"
						+ "        }"
						+"@font-face {font-family: adobeFont;src:url(\"file:///android_asset/fonts/adobe_black.otf\")}@font-face {font-family: dqFont;src:url(\"file:///android_asset/fonts/dq_black.otf\")"
						);

				ByteArrayInputStream inputStream = new ByteArrayInputStream(
						builder.toString().getBytes());
				return new WebResourceResponse("text/css", "UTF-8",
						inputStream);
			}

			return null;
		}
	});

	webView.loadUrl("file:///android_asset/book.html");
}
```

3、提取内容可以动态加载（便于后面和服务器交互）
将id为content的div内容提取出来，通过ajax加载，修改后的html（提取的内容放到了data.html中）

```html

<html>
<head>
    <title>天蝎座</title>
    <meta charset="utf-8">
    <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0,width=device-width,user-scalable=no">
    <script src="jquery-1.9.1.min.js"></script>
    <link href="book.css" rel="stylesheet" type="text/css">
    <style>
	    span {
	    	padding:0px;
			margin:0px 0px 0px 0px;
			background-color: #ffd7b6;
		}
    </style>
</head>
<body >
<div id="content"></div>
<script>
    $(document).ready(function(){
        $('#content').load('data/data.html',function(){
        });
    });
</script>
</body>
</html>
```

4、服务器端生成模版化数据

略


####项目参考
	https://github.com/pangff/RM/tree/m1