---
layout: post
title: "Android打开pdf文件"
date: 2016-03-12 17:54:51 +0800
comments: true
categories: Android pdf
---
项目中有个阅读pdf的需求，总结下几种方案
<!--more-->

### 方案一：采用GoogleDocs

优势：

- 非常简单，而且可以直接通过webview打开线上pdf（不要忘记开启网络权限）

```java

@SuppressLint("SetJavaScriptEnabled")
public void setDocumentPath(final String path) {
    WebView webView = (WebView) findViewById(R.id.webview);
    webView.getSettings().setJavaScriptEnabled(true);
    webView.getSettings().setPluginsEnabled(true);
    webView.loadUrl("https://docs.google.com/viewer?url=http://www.selab.isti.cnr.it/ws-mate/example.pdf");
}
```

缺点：

- 国内访问google你懂的

当然也有解决方案：

- 可以在自己的服务器做一个代理

### 方案二：将pdf的Intent抛出

优势：

- 也很简单，目前大部分Android设备貌似都有pdf阅读器

```java

File file = new File(Environment.getExternalStorageDirectory().getAbsolutePath() +"/"+ filename);
Intent target = new Intent(Intent.ACTION_VIEW);
target.setDataAndType(Uri.fromFile(file),"application/pdf");
target.setFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);

Intent intent = Intent.createChooser(target, "Open File");
try {
    startActivity(intent);
} catch (ActivityNotFoundException e) {
    // Instruct the user to install a PDF reader here, or something
}

```
缺点：

- 不能在应用内打开，如果用户手机没有pdf阅读器就不行了

方案三：使用Android PdfRenderer

优势：

- 应用内集成

缺点：

- 不能滚动，只能单页，操作不方便

### 方案四：集成三方pdf sdk

优势：

- 应用内集成，有现成解决方案

推荐三方sdk：

- <https://www.qoppa.com/android/pdfsdk/>  使用了下demo感觉体验不是很好
- <https://code.google.com/archive/p/mupdf> 貌似需要编译
- 当然还有比较不错的需要收费

缺点：

- 应用包会变大，三方出现问题的话，不好调试