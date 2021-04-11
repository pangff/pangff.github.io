---
layout: post
title: "内存泄漏的监测与修复"
date: 2015-03-17 15:52:06 +0800
comments: true
categories: [Android, 性能优化]
---

在android开发中，我们经常会遇到OutOfMemory的问题。有的由于listview中没有通过ViewHolder复用item，有的由于图片过大没有压缩，当然最多的还是由于我们在开发中不小心造成的内存泄漏。结合本人的开发经验，下面我们来重点看下如何监测我们的内存泄漏问题以及如何定位解决它。
<!--more-->

#### 如何监测 ####
在我们的开发阶段当出现OutOfMemory的时候，我们往往不能直接根据日志来定位它到底是由于什么造成的。为了解决这个问题，在我们的项目中采用了“面包屑”的原理（就是跟踪纪录每一个Activity的生成和释放）。

* 我们在BaseApplication（它继承Application，在AndroidManifest.xml的application标签配置android:name）中初始化两个存放Activity的list，分别叫listCurrent、listLeak（采用弱引用WeakReference<Activity>，否则listLeak持有的activity都不能释放）。
* 在Activity的onCreate中listCurrent添加该Activity，同时遍历listLeak进行已释放activity的remove(弱引用为空或者get()为空时说明该弱引用的Activity已经释放)
* 然后在Activity的onDestory方法中listCurrent进行该activity的remove操作。
* 这样当我们捕获全局异常时候，就可以打印出listCurrent、和listLeak，listCurrent就是我们操作过的全部Activity栈，而listLeak就是当前尚未释放的Activity，结合当前应用开启的Activity就可以判断是不是已经关闭的Activity仍然没有释放而存在在listLeak中。

如果出现了OutOfMemory，那么我们优先要检查的就是listLeak中并且不在listCurrent中的Activity了。

#### 如何定位 ####

找到了这些存在内存泄漏问题的Activity后我们该如何准确定位到，它泄漏的原因呢？那就要用到内存泄漏检测定位的神器DDMS的"DUMP HPROF File"功能结合 MAT(Memory Analyzer，有eclipse插件(https://eclipse.org/mat/)，安装后可以直接通过DUMP HPROF File 后自动打开hprof文件)了。


#### 举个例子 ####

创建Android项目memoryleakanalyzer

定义BaseApplication

```java

public class BaseApplication extends Application {

	public ArrayList<Activity> listCurrent;//当前activity列表
	public ArrayList<WeakReference<Activity>> listLeak;//泄漏列表

	public static BaseApplication instance;
	
	@Override
	public void onCreate() {
		super.onCreate();
		instance = this;
		listCurrent = new ArrayList<Activity>();
		listLeak = new ArrayList<WeakReference<Activity>>();
	}
	
	/**
	 * 添加activity，在activity的onCreate中
	 * @param activity
	 */
	public void addActivity(final BaseActivity activity) {
		listCurrent.add(activity);
		synchronized (listLeak) {
			for (int j = listLeak.size() - 1; j >= 0; j--) {
				WeakReference<Activity> wr = listLeak.get(j);
				if (wr == null || wr.get() == null) {
					listLeak.remove(j);
				}
			}
			listLeak.add(new WeakReference<Activity>(activity));
		}
	}

	/**
	 * activity的destory中删除
	 * @param activity
	 */
	public void removeActivity(final BaseActivity activity) {
		listCurrent.remove(activity);
	}
}

```



全局异常处理打印activity信息

```java

@Override
	public void uncaughtException(final Thread thread, final Throwable ex) {
		if (ex == null) {
			return;
		}

		if (lastThrowable == ex || ex.getCause() != null
				&& lastThrowable == ex.getCause()) {
			android.os.Process.killProcess(android.os.Process.myPid());
			System.exit(1);
			return;
		}

		StringBuilder sbActivities = new StringBuilder();
		sbActivities.append("activities: ");
		StringBuilder sbLeakActivities = new StringBuilder();
		sbLeakActivities.append("leak activities: ");
		ArrayList<WeakReference<Activity>> list = BaseApplication.instance.listLeak;
		for (WeakReference<Activity> wr : list) {
			if (wr == null) {
				continue;
			}
			Activity activity = wr.get();
			if (activity == null) {
				continue;
			}
			sbActivities.append(activity.getClass().getSimpleName()).append(", ");
			if (!BaseApplication.instance.listCurrent.contains(activity)) {
				sbLeakActivities.append(activity.getClass().getSimpleName()).append(", ");
			}
		}
		sbActivities.append("\n").append(sbLeakActivities);

		Throwable myThrowable = ex;

		if (ex instanceof Exception) {
			myThrowable = new Exception(sbActivities.toString(), ex);
		} else if (ex instanceof Error) {
			myThrowable = new Error(sbActivities.toString(), ex);
		}

		lastThrowable = myThrowable;
		
		//交还给系统处理，我们只是在wrapperThrowable附加信息
		mSystemDefaultHandler.uncaughtException(thread, myThrowable);
		return;

	}
	
```


定义BaseActivity

```java

public class BaseActivity extends Activity{
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		BaseApplication.instance.addActivity(this);
		MyCrashHandler.getInstance().setDefaultUncaughtExceptionHandler();
	}
	
	@Override
	protected void onDestroy() {
		super.onDestroy();
		BaseApplication.instance.removeActivity(this);
	}
}

```

MainActivity中跳转到LeakAtivity

```java

public class MainActivity extends BaseActivity {

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
	}
	
	public void gotoLeakActivity(View view){
		Intent intent = new Intent();
		intent.setClass(this, LeakActivity.class);
		startActivity(intent);
	}
}

```

LeakActivity模拟内存泄漏

```java

public class LeakActivity extends BaseActivity{
	
	public static  int MSG = 0;
	private Handler handler = new MyHandler();
	ArrayList<String> list = new ArrayList<String>();
 	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_leak);
		
		handler.sendEmptyMessage(MSG);
	}
	
 	/**
 	 * 模拟内存泄漏
 	 * @author pangff
 	 */
	private class MyHandler extends Handler {
	    @Override
	    public void handleMessage(final Message msg) {
	      super.handleMessage(msg);
	      if(msg.what == MSG){
	    	  		for(int i=0;i<10000;i++){
	    	  			list.add(String.valueOf(i));//为了尽快的造成OutOfMemory
	    	  		}
				handler.sendEmptyMessageDelayed(MSG, 1000);//循环发送消息
		  }
	    }
	  }
	
	@Override
	protected void onDestroy() {
		super.onDestroy();
		//handler.removeMessages(MSG);
	}
}

```
我们运行程序从MainActivity点击leak activity到leak activity然后后退退出leak activity再进入，多次重复几次后会出现如图异常

![](http://www.pffair.com/images/38.png)

根据日志我们可以看到我们点击了5次leak acitivity进入LeakActivity并且都退出了。日志中leak activitys：应该是没有的然而日志中确出现了5次，很显然我们的LeakActivity存在内存泄漏。

下面我们来找到LeakActivity中泄漏问题根源

进入eclipse的ddms模式，如图

![](http://www.pffair.com/images/39.png)

选中我们的项目进程点击DUMP HPROF file按钮，如图

![](http://www.pffair.com/images/40.png)

等待生成hprof文件并用mat打开，打开后选择leak report，如图

![](http://www.pffair.com/images/41.png)

然后进入leak report，如图

![](http://www.pffair.com/images/42.png)

我们不看这个报告，因为我们已经知道了具体位置，打开Dominaor视图，如图

![](http://www.pffair.com/images/43.png)


然后输入我们要找的LeakActivity进行过滤，发现果然有好几个LeakActivity实例（按正常来说我们退出了应该都销毁不存在才对，存在说明内存泄漏了）如图

![](http://www.pffair.com/images/44.png)

然后我们选中一个，到incoming refrence这样清晰看到LeakActivity持有的内容，如图

![](http://www.pffair.com/images/45.png)

然后我们再选择Path TO GC Roots（如果存在GC Roots说明没有释放）来找到它未被回收的原因，如图 

![](http://www.pffair.com/images/46.png)

结果，如图

![](http://www.pffair.com/images/47.png)

根据上面的图可以看到原因出在我们的内部类MyHandler上，循环发送了消息到主线程的消息队列。handler一直未被释放而它的外部类LeakActivity也不能被释放(默认的内部类会持有外部类的引用)。这下我们就知道该怎么改了吧.最简单方法，在LeakActivity中的onDestory中在消息队列中删除这个MSG消息，如下代码

```java

@Override
	protected void onDestroy() {
		super.onDestroy();
		handler.removeMessages(MSG);
	}


```

我们再次测试会发现不会出现OutOfMemory了。然后使用MAT重复检测步骤LeakActivity的实例一个也不见了，内存问题解决。

测试代码地址

```
https://github.com/pangff/MemoryLeakAnalyzer

```
