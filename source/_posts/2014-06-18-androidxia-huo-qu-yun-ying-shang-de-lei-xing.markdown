---
layout: post
title: "Android下获取运营商的类型"
date: 2014-06-18 17:27:50 +0800
comments: true
categories: Android
---

####大家熟知的国内三大运营商：移动、联通、电信

----

#####问题1:

   * 我们在列举支付方式时，如何根据当前SIM来判断应该采用那个运营商的支付方式？
   
<!--more-->

#####解决方式(代码如下):
```java

TelephonyManager tManager = (TelephonyManager) 	this.getSystemService(TELEPHONY_SERVICE);
 
if(tManager!=null){

String imsi = tManager.getSubscriberId();

if(imsi!=null){

if (imsi.startsWith("46000") || imsi.startsWith("46002")) {

yunyin = "中国移动";

} else if (imsi.startsWith("46001")) {

yunyin = "中国联通";

} else if (imsi.startsWith("46003")) {

yunyin = "中国电信";

}

}

}
```

#####问题2:
* 如果遇到双卡双待要取得副卡的运营商类型的情况该如何处理呢？(如果沿用问题1的方式会默认取主卡信息)

#####解决方式(代码如下):

```java

//可能存在双卡

//获取phone2服务
TelephonyManager tManager2 = (TelephonyManager)this.getSystemService("phone2");

if(tManager2!=null){

String imsi2 = tManager2.getSubscriberId();

if(imsi2!=null){

if (imsi2.startsWith("46000") || imsi2.startsWith("46002")) {

yunyin += "|中国移动";

} else if (imsi2.startsWith("46001")) {

yunyin += "|中国联通";

} else if (imsi2.startsWith("46003")) {

yunyin += "|中国电信";

}

}

}

```
 
<font color='red'>注意：
对于问题2的解决方式只用了一个motorola的机器进行验证，验证通过。对于该方法具不备具备普遍性还有待进一步的验证</font>