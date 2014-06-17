---
layout: post
title: "Android快捷方式的创建与删除问题"
date: 2014-06-17 11:17:29 +0800
comments: true
categories: android
---

项目中遇到了对于桌面快捷方式的操作。

####需求：

   * 创建快捷方式时如果之前已经存在就不重复创建。

####问题：

   * 通过在创建快捷方式时，设置shortcutIntent.putExtra("duplicate", false);会避免重复创建
   * 但是会在已存在快捷方式时出现 “该快捷方式已存在”的toast。

####解决思路：

  1. 修改编译源码（pass掉）
  2. 先删除再创建

####解决方法：采用第2种
	解决方法注意事项：创建和删除Intent配置要一样
 
####创建和删除代码：
	
	  /**
	  * 创建快捷方式
	  */
	 public void createDeskShortCut() { 
	Intent shortcutIntent = new Intent("com.android.launcher.action.INSTALL_SHORTCUT");
	shortcutIntent.putExtra("duplicate", false);
	shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_NAME, getString(R.string.app_name));
	Parcelable icon =
		Intent.ShortcutIconResource.fromContext(getApplicationContext(), R.drawable.icon);
	shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, icon);
	Intent intent = null;
	intent = new Intent(getApplicationContext(), LoadImageActivity.class);
	intent.setAction("android.intent.action.MAIN");
	intent.addCategory("android.intent.category.LAUNCHER");
	shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, intent);
	sendBroadcast(shortcutIntent);
	 }

  
	 /**
	   * 删除当前应用的桌面快捷方式
	   * 注意，删除的配置要合创建的配置相同才能删掉
	   * @param cx
	   */
	  public static void delOldShortcut(Context cx) {
	 
		Intent shortcutIntent = new Intent("com.android.launcher.action.UNINSTALL_SHORTCUT");
		// 不允许重复创建
		shortcutIntent.putExtra("duplicate", false);
		// 需要现实的名称
		shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_NAME, cx.getString(R.string.app_name));
		// 快捷图片
		Parcelable icon = Intent.ShortcutIconResource.fromContext(cx.getApplicationContext(), R.drawable.icon);
		shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_ICON_RESOURCE, icon);
		Intent intent = null;
		intent = new Intent(cx.getApplicationContext(), LoadImageActivity.class);
		intent.setAction("android.intent.action.MAIN");
		intent.addCategory("android.intent.category.LAUNCHER");
		shortcutIntent.putExtra(Intent.EXTRA_SHORTCUT_INTENT, intent);
		cx.sendBroadcast(shortcutIntent);
		}