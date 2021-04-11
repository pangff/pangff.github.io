---
layout: post
title: "WebView图片上传的各种坑"
date: 2016-04-01 15:56:05 +0800
comments: true
categories: Android WebView FileChooser
---
最近项目用到了应用内webview图片上传，虽然最终实现了，但是遇到了各种坑，抽时间总结一下。
<!--more-->

我们在应用中用webview加载了一个wap页面，该wap页面需要通过input标签调起本地文件选择。看了前人遗留的webview代码，有重写WebChromeClient的openFileChooser方法，但是经过测试在有些设备上只弹出一次文件选择取消后就再也弹不出来，有些设置上干脆一次都不会弹出来。至此，走向webview文件选择的填坑之路。

### 首先解决一次都弹不出的问题。

经过测试发现这个问题集中在5.0以上的设备，忽然有点儿印象在5.0以上WebChromeClient貌似是做过改动，翻下api发现果然多了一个onShowFileChooser方法。重写WebChromeClient onShowFileChooser 并返回true。这时候在5.0、6.0设备上可以弹出了，但是还是像之前能弹出的设备一样取消后就再也出不来了

### 接下来解决某些设备只弹出一次问题

在stackoverflow搜了半天也没有找到合适答案，于是再看了下onShowFileChooser的api，忽然发现了一句话

```
To cancel the request, call filePathCallback.onReceiveValue(null) and return true.
```
恍然大悟，原来取消依然是需要回调onReceiveValue。因此在当前页面onResume时候加上如下代码

``` java
if(filePathCallback!=null){
   filePathCallback.onReceiveValue(null);
}        
```
问题得到解决。需要注意的是在onActivityResult中回调后要将filePathCallback置空，否则当选择一个图片或者拍照返回到页面时onActivityResult 和 onResume都会触发，而且onActivityResult 在 onResume之前。因此不在onActivityResult置空filePathCallback的话会触发两次回调，可能会产生问题（没有验证）.

后面进行正常上传，发现onActivityResult一直不回调。因为webview是在Fragmengt中，因此代码中将Activity的onActivityResult委托给了该Activity下面的WebviewFragment中，如下代码

```java
else if (requestCode == WebViewFragment.FILECHOOSER_RESULTCODE){
    if(mFragment!=null){
       mFragment.onActivityResult(requestCode,resultCode,data);
    }
}            
```
但是requestCode == WebViewFragment.FILECHOOSER_RESULTCODE的条件判断一直是false，奇怪...


### Fragment startActivityForResult的坑
Debug代码进入fragment源码中发现调用顺序是 Fragment［startActivityForResult］->［FragmentActivity］onStartActivityFromFragment -> ［FragmentActivity］ startActivityFromFragment。就在这个方法中,看下源码

```java
/**
     * Called by Fragment.startActivityForResult() to implement its behavior.
     */
    public void startActivityFromFragment(Fragment fragment, Intent intent,
            int requestCode) {
        if (requestCode == -1) {
            super.startActivityForResult(intent, -1);
            return;
        }
        if ((requestCode&0xffff0000) != 0) {
            throw new IllegalArgumentException("Can only use lower 16 bits for requestCode");
        }
        super.startActivityForResult(intent, ((fragment.mIndex+1)<<16) + (requestCode&0xffff));
    }
```
你会发现super.startActivityForResult的requestCode被改变了,后16位前拼了fragment.mIndex+1。这时候你的Ativity将永远不会返回你之前传的requestCode。解决方法,使用activity去调用就可以了

```java
 getActivity().startActivityForResult(chooserIntent, FILECHOOSER_RESULTCODE);
``` 

现在结束了吗？debug包没问题一切正常。试试release，忽然发现又打不开了。难道和混淆有关系？查了一下还真是

### 解决混淆问题

```java
-keepclassmembers class * extends android.webkit.WebChromeClient {
     public void openFileChooser(...);
     public void onShowFileChooser(...);
}
```

终于解决了。

之后又看了一些资料，其实openFileChooser一直都没有在Android API中开放，有个[stackoverflow上的说明比较详细](http://stackoverflow.com/questions/30078217/why-openfilechooser-in-webchromeclient-is-hidden-from-the-docs-is-it-safe-to-us)


	Using the old openFileChooser(...) callbacks does not have any security implications. It's just fine. The only downside is that it will not be called on some platform levels and therefore not work.

	void openFileChooser(ValueCallback<Uri> uploadMsg) works on Android 2.2 (API level 8) up to Android 2.3 (API level 10)

	openFileChooser(ValueCallback<Uri> uploadMsg, String acceptType) works on Android 3.0 (API level 11) up to Android 4.0 (API level 15)
	openFileChooser(ValueCallback<Uri> uploadMsg, String acceptType, String capture) works on Android 4.1 (API level 16) up to Android 4.3 (API level 18)

	onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback, WebChromeClient.FileChooserParams fileChooserParams) works on Android 5.0 (API level 21) and above
	You can use a library that abstracts this away and takes care of all these callbacks on different platform levels so that it just works.

	The fact that it's undocumented just means that you can't rely on it. When it was introduced in Android 2.2, nobody could know that it would stop working in Android 4.4, but you had to accept it.

之后测试了几个4.4-5.0直间的设备并没有发现问题，可能国内厂商对系统做了处理吧，没有试原生系统在4.4-5.0区间是否真的有问题，感兴趣的可以试试。