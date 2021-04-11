---
layout: post
title: "对象池的使用"
date: 2015-03-30 10:38:04 +0800
comments: true
categories: [Android, 性能优化]
---

在android开发中经常会发现当日志中出现大量GC时我们的应用常常出现卡顿。这是因为当虚拟机进行垃圾回收操作时应用所有线程都会暂停，完成后恢复。如果出现大量GC操作时主线程频繁暂停就会影响应用性能了。所以我们在开发中要尽量避免。

<!--more-->

## 了解Android 垃圾回收 ##
Android里面是一个三级Generation的内存模型，最近分配的对象会存放在Young Generation区域，当这个对象在这个区域停留的时间达到一定程度，它会被移动到Old Generation，最后到Permanent Generation区域。每一个级别的内存区域都有固定的大小，此后不断有新的对象被分配到此区域，当这些对象总的大小快达到这一级别内存区域的阀值时，会触发GC的操作，以便腾出空间来存放其他新的对象。每次GC发生的时候，所有的线程都是暂停状态的。GC所占用的时间和它是哪一个Generation也有关系，Young Generation的每次GC操作时间是最短的，Old Generation其次，Permanent Generation最长。

导致GC频繁执行有两个原因：

* Memory Churn内存抖动，内存抖动是因为大量的对象被创建又在短时间内马上被释放。
* 瞬间产生大量的对象会严重占用Young Generation的内存区域，当达到阀值，剩余空间不够的时候，也会触发GC。即使每次分配的对象占用了很少的内存，但是他们叠加在一起会增加Heap的压力，从而触发更多其他类型的GC。这个操作有可能会影响到帧率，并使得用户感知到性能问题。

## 如何避免 ##
根据上面GC频繁原因我们可以得出一个简单结论，那就是我们的代码中在卡顿那个操作中进行了大量的对象创建。当然这个还可以通过 Android studio的 Memory Monitor 内存浮动观察到；也可以通过Allocation Tracker来跟踪问题出现的位置。但是我认为直接去看卡顿操作部分对应的代码，应该很容易发现。

## 如何解决 ##
回到主题，如果我们发现了大量对象的创建该如何处理呢？

* 可以优化就优化，比如在onDraw中初始化了一些对象，我们可以考虑是否可以将这些对象初始化到外部（比如构造方法），而不要在视图绘制需要反复调用的方法中去new
* 不能优化的采用对象池解决，如果我们这些对象的初始化不可避免，那么我们要考虑对象的复用，采用对象池来解决

## 对象池 ##
我们在Android开发中其实可能已经使用过，只是我们没用关注而已。比如在handler发送消息时，Message的初始化经常会用Message.obtain()来实例化Message对象；在View自定义中用到手势速度控制的VelocityTracker。根据源码虽然两者对实现方式不同（Message使用链表、VelocityTracker使用数组），但是原理是一样的。即：

```
初始化一个固定大小池子，我们每次创建对象时候先去池子中找有没有，
如果有直接取出，没有new出来使用后还到池子里。这样便可达到对象
复用的目的
```
## 使用对象池的代价以及注意事项 ##
#### 当然使用对象池也是要有一定代价的：####

* 短时间内生成了大量的对象占满了池子，那么后续的对象是不能复用的
* 对象池是静态的，如果池子被占满，当我们离开该页面这些对象可能不再需要，那么池子不释放其中的无用对象还是要占用一定的内存空间

#### 注意事项: ####
* 使用时候申请(obtain)和释放(recycle)成对出现，使用一个对象后一定要释放还给池子
* 池子的大小要根据实际情况合理指定。池子太大上面提到的不释放而占用的内存会很大，池子太小对象过多而且因为操作耗而不能立即释放还给池子时候，池子满了，后续对象还是不能复用。所以，根据项目实际场景制定合理的大小是很必要的

## 对象池的创建方法 ##
有很多方法都可以实现，比如Message的链表、或者自己实现都可以，但是为了简便这里只说一种最简便方法。采用Android的SynchronizedPool，以一个User的对象池为例

```java

public class User {

	public String id;
	public String name;

	private static final SynchronizedPool<User> sPool = new SynchronizedPool<User>(
			10);

	public static User obtain() {
		User instance = sPool.acquire();
		return (instance != null) ? instance : new User();
	}

	public void recycle() {
		sPool.release(this);
	}
}


```

我们在申请实例化时调用

```java
//从对象池中获取，第一次对象池没有，会直接new一个,如果有会复用
User user = User.obtain();
```
对象使用完释放时调用

```java
//使用完毕务必要将对象归还到对象池
user.recycle();
```

##demo的源代码##

<https://github.com/pangff/ObjectPoolDemo>

