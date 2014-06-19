---
layout: post
title: "github-octopress博客切换电脑怎么办"
date: 2014-06-19 16:17:51 +0800
comments: true
categories: 备忘
---

在使用github－octopress搭建博客后，如遇到换电脑的情况改怎么办呢？
<!--more-->

一、保证之前每次本地内容都提交到了github（source目录）
二、切换之后

```c

git clone git@github.com:username/username.github.io.git

cd username.github.io

git checkout source

mkdir _deploy

cd _deploy

git init

git remote add origin git@github.com:username/

username.github.io.git

git pull origin master

cd ..
```

三、换回原来电脑时候

```c

//先更新source
git pull origin source

//更新master
cd _deploy
git pull origin master
cd ..

```