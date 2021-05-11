---
layout: post
title: "React+Redux learn"
date: 2016-05-17 21:33:55 +0800
comments: true
categories: js
---
之前一直想尝试react苦于没有时间。最近有前端项目用到所以简单学习总结一下。
先看一个react的[hello world](https://github.com/pangff/react-redux-learn/blob/master/demo01/index.html)

<!--more-->

#### React Hello world

```
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <script src="../build/react.js"></script>
    <script src="../build/react-dom.js"></script>
    <script src="../build/browser.min.js"></script>
  </head>
  <body>
    <div id="example"></div>
    <script type="text/babel">
      ReactDOM.render(
        <h1><a href='https://facebook.github.io/react/'>React 官网</a> <br/><br/> <a href='http://reactjs.cn/'>React 中文</a></h1>,
        document.getElementById('example')
      );
    </script>
  </body>
</html>


```

代码很简单，引入react相关js。然后使用ReactDOM.render将相关内容渲染到div上。需要注意的是render第一个参数看起来像一组html标签，其实是JSX语法。根据一张图看下JSX渲染机制

![JSX](http://www.pffair.com/images/50.png)

React会将JSX文件翻译成javaScript文件，在运行时React会将javascript转换成虚拟dom，然后将虚拟dom渲染成真实dom节点，当虚拟dom有变化时只会同步最小变化到真实dom，这也是react速度快的原因。


*为什么先生成虚拟dom再渲染真实dom速度会比直接操作dom快呢？两步为什么比一步快呢？对于单个节点两步肯定是比一步要慢一些，但是我们经常操作的往往都是多层嵌套的复杂节点。举一个表格的数据更新为例，如果直接操作dom的话，我们一般会直接遍历数据然后动态更新全部表格数据，这样有多少单元格那么我们就要同时操作多少节点；而React会先在虚拟dom做这一步，然后和之前数据比较只跟新变化了的单元格的节点。想象一下如果表格有100条数据而只有1个数据变化，操作100个节点和操作1个节点的速度是可想而知的(这些是个人理解欢迎指正)*
	

#### React 组件

下面用一个简单[demo](https://github.com/pangff/react-redux-learn/tree/master/demo02)来看下react的组件

```
<!DOCTYPE html>
<html>
  <head>
    <script src="../build/react.js"></script>
    <script src="../build/react-dom.js"></script>
    <script src="../build/browser.min.js"></script>
  </head>
  <body>
    <div id="example"></div>
    <script src="./app.js" type="text/babel"></script>
  </body>
</html>
```


```
/**
 * Created by pangff on 16/5/5.
 */
var Activity = React.createClass({
    render:function() {
        return (
            <div style={{height:300+'px',background:'#F00000'}}>
                <h1>Activity</h1>
            </div>
        );
    }
});


var Share = React.createClass({

    render:function() {
        return (
            <div style={{height:300+'px',background:'#F23456'}}>
                <h1>Share</h1>
            </div>
        );
    }
});


var ShareRank = React.createClass({

    render:function() {
        return (
            <div style={{height:300+'px',background:'#F98928'}}>
                <h1>ShareRank</h1>
            </div>
        );
    }
});

 var MyApp = React.createClass({

    render:function() {
        return (
            <div>
                <Share/>
                <Activity />
                <ShareRank />
            </div>
        );
    }
});

ReactDOM.render(<MyApp />,document.getElementById('example'));

```
代码也很简单，我们在index.html中引入了app.js。这个demo我们是设想一个页面可以划分为分享块、活动块、分享排名块，而react的组件非常有利于这样划分的实现。我们可以将页面划分为Share、Activity、ShareRank三个组件，这样有利于组件复用，并有利于模块化和开发人员的分工。看下丑陋的运行效果

![react组件化](http://www.pffair.com/images/51.png)

#### React 组件生命周期

看个图

![react生命周期](http://www.pffair.com/images/52.jpg)

根据图可以看到，可以大体将整个生命周期划分为3部分，初始化、运行中、卸载。

初始化过程：

* getDefaultProps：在第一次启动组件时会调用,获取初始化的props数据
* getInitialState：在第一次启动组件时会调用,获取初始化的state数据
* componentWillMount：服务器端和客户端都只调用一次，在初始化渲染执行之前立刻调用。如果在这个方法内调用 setState，render() 将会感知到更新后的 state，将会执行仅一次，尽管 state 改变了
* render：返回虚拟Dom
* componentDidMount：在初始化渲染执行之后立刻调用一次，仅客户端有效（服务器端不会调用）。在生命周期中的这个时间点，组件拥有一个 DOM 展现，你可以通过 this.getDOMNode() 来获取相应 DOM 节点

运行中：

* componentWillReceiveProps：在组件接收到新的 props 的时候调用。在初始化渲染的时候，该方法不会调用。
用此函数可以作为 react 在 prop 传入之后， render() 渲染之前更新 state 的机会。老的 props 可以通过 this.props 获取到。在该函数中调用 this.setState() 将不会引起第二次渲染。
* shouldComponentUpdate：在接收到新的 props 或者 state，将要渲染之前调用。该方法在初始化渲染的时候不会调用，在使用 forceUpdate 方法的时候也不会。
如果确定新的 props 和 state 不会导致组件更新，则此处应该 返回 false。
如果 shouldComponentUpdate 返回 false，则 render() 将不会执行，直到下一次 state 改变。（另外，componentWillUpdate 和 componentDidUpdate 也不会被调用。）默认情况下，shouldComponentUpdate 总会返回 true，在 state 改变的时候避免细微的 bug，但是如果总是小心地把 state 当做不可变的，在 render() 中只从 props 和 state 读取值，此时你可以覆盖 shouldComponentUpdate 方法，实现新老 props 和 state 的比对逻辑。如果性能是个瓶颈，尤其是有几十个甚至上百个组件的时候，使用 shouldComponentUpdate 可以提升应用的性能。
* componentWillUpdate：componentWillUpdate(object nextProps, object nextState)
在接收到新的 props 或者 state 之前立刻调用。在初始化渲染的时候该方法不会被调用。
使用该方法做一些更新之前的准备工作。你不能在该方法中使用 this.setState()。如果需要更新 state 来响应某个 prop 的改变，请使用 componentWillReceiveProps。
* componentDidUpdate：componentDidUpdate(object prevProps, object prevState)
在组件的更新已经同步到 DOM 中之后立刻被调用。该方法不会在初始化渲染的时候调用。
使用该方法可以在组件更新之后操作 DOM 元素。

卸载：

* componentWillUnmount:componentWillUnmount()
在组件从 DOM 中移除的时候立刻被调用。在该方法中执行任何必要的清理，比如无效的定时器，或者清除在 componentDidMount 中创建的 DOM 元素。


再看个简单[demo](https://github.com/pangff/react-redux-learn/tree/master/demo03)

```

<!DOCTYPE html>
<html>
  <head>
    <script src="../build/react.js"></script>
    <script src="../build/react-dom.js"></script>
    <script src="../build/browser.min.js"></script>
  </head>
  <body>
    <div id="example"></div>
    <script src="./app.js" type="text/babel"></script>
  </body>
</html>



```

```

var Share = React.createClass({
    componentWillMount: function () {
        console.log("Share>>>>componentWillMount")
    },
    componentDidMount: function () {
        console.log("Share>>>>componentDidMount")
    },
    componentWillReceiveProps: function () {
        console.log("Share>>>>componentWillReceiveProps")
    },
    shouldComponentUpdate: function () {
        console.log("Share>>>>shouldComponentUpdate")
        return true;
    },
    componentWillUpdate: function () {
        console.log("Share>>>>componentWillUpdate")
    },
    componentDidUpdate: function () {
        console.log("Share>>>>componentDidUpdate")
    },
    componentWillUnmount: function () {
        console.log("Share>>>>componentWillUnmount")
    },
    render: function () {
        var params = this.props.params;
        return (
            <div style={{height:300+'px',background:'#F23456'}}>
                <h1>Share=={params}</h1>
            </div>
        );
    }
});


var MyApp = React.createClass({
    getInitialState:function(){
        console.log("MyApp>>>>getInitialState")
        return {shareParams:'0'}
    },
    getDefaultProps:function(){
        console.log("MyApp>>>>getDefaultProps")
        return {shareParams:'0'}
    },
    componentWillMount: function () {
        console.log("MyApp>>>>componentWillMount")
    },
    componentDidMount: function () {
        console.log("MyApp>>>>componentDidMount")
    },
    componentWillReceiveProps: function () {
        console.log("MyApp>>>>componentWillReceiveProps")
    },
    shouldComponentUpdate: function () {
        console.log("MyApp>>>>shouldComponentUpdate")
        return true;
    },
    componentWillUpdate: function () {
        console.log("MyApp>>>>componentWillUpdate")
    },
    componentDidUpdate: function () {
        console.log("MyApp>>>>componentDidUpdate")
    },
    componentWillUnmount: function () {
        console.log("MyApp>>>>componentWillUnmount")
    },
    changeShareParam:function(){
        console.log("MyApp>>>>changeShareParam")
        this.setState({shareParams:'1'});
    },
    render: function () {
        return (
            <div>
                <button onClick={this.changeShareParam}>修改share参数</button>
                <Share params={this.state.shareParams}/>
            </div>
        );
    }
});

ReactDOM.render(<MyApp />, document.getElementById('example'));

```

这个demo中我们打印了父组件和子组件的生命周期，看下运行结果

![react生命周期](http://www.pffair.com/images/57-2.png)

首次加载-日志

* MyApp>>>>getDefaultProps
* MyApp>>>>getInitialState
* MyApp>>>>componentWillMount
* Share>>>>componentWillMount
* Share>>>>componentDidMount
* MyApp>>>>componentDidMount

点击按钮后－日志

* MyApp>>>>changeShareParam
* MyApp>>>>shouldComponentUpdate
* MyApp>>>>componentWillUpdate
* Share>>>>componentWillReceiveProps
* Share>>>>shouldComponentUpdate
* Share>>>>componentWillUpdate
* Share>>>>componentDidUpdate
* MyApp>>>>componentDidUpdate

根据日志可以了解到运行结果和生命周期的图是一致的。

#### React 数据事件传递（props，state）
React中通过props来进行父组件到子组件间的数据传递，通过state来控制本组件内部的数据状态变化。当本组件的props和state发生变化时一般都会触发页面的重新渲染（一般是指还要根据shouldComponentUpdate返回true和false的状态等判定）。而子组件和父组件通信是通过父组件将一个回调事件通过props传递给子组件，然后子组件内部调用改回调方法并将需要的参数数据通过方法参数传给父组件。具体依旧可参考上面的例子中MyApp render的button事件处理

关于state和props的区别，本人理解是：

* props做组件间的数据传递，由父组件传递（或getDefaultProps）初始化，在组件内部不可变
* state是组件内私有，通过setState改变state数据，达到更新当前组件页面状态效果

理解有限，推荐大家可以详细看下官网相关内容：

* [Communicate Between Components](https://facebook.github.io/react/tips/communicate-between-components.html)
* [Transferring Props](https://facebook.github.io/react/docs/transferring-props.html)
* [Interactivity and Dynamic UIs](https://facebook.github.io/react/docs/interactivity-and-dynamic-uis.html)

#### Redux
react在传统MVC架构模式中，只是单单的View。因此在复杂项目中，数据处理和View以及相关业务都要参杂在一起。facebook出了flux来搭配react进行相关数据流的处理。Redux由Flux演变，受Elm启发，避开Flux复杂性。下面只简单了解写Redux的结构，具体学习Redux推荐大家看[Redux的官网](http://redux.js.org/),英语不好可以看[中文版](https://github.com/camsong/redux-in-chinese)

 来看张图
 
 ![Redux结构](http://www.pffair.com/images/54.png)
 
 先了解下图上几个名词意义：
 
 * Views：就是普通dom，可以是普通dom，可以是react的组件，取决于用什么来实现
 * Action Creator：其实就是普通js function，可以理解为产生Action的方法
 * Action：普通js对象，存储了事件的类型、和事件要改变为的数据
 * state：全局状态数据存储树，可以理解为整个应用的状态数据中心，请和React的state区别，他们没有任何直接关系
 * reducer：一个方法，接收旧的state和action作为参数，返回一个新的state。combineReducers就是多个reducer的集合
 * store：可以理解为一个枢纽或管理者，它将action和上一次的state分发给reducer，reducer根据旧的state和action进行数据处理返回一个新的state，然后store通知view层数据变化，view层会拿到变化后的state来进行相关页面渲染
 
了解了相关名词其实Redux的工作原理基本就清晰了，也是一个单向数据流（这里不讨论单项数据流双向数据流的优劣，各有优势）。view的每次操作都看成是触发一个Action，当然这个action可以用方法（也就是action creator）封装一下，然后用store.dispath(action)将这个action分发到reducer，reducer根据上一次的state和当前的action做出处理后返回新的state，然后store通知view state数据发生了变化，view拿到新的state进行页面处理

#### Redux middleware
 
 还是先看图
 
 ![Redux middleware结构](http://www.pffair.com/images/55.png)
 
 根据图看到相比上一个图Actions和reducer之间多了一层middleware。顾名思义，它作为中间件就是在action最终由store分发前对action做一些处理，比如加一些日志调试，比如加异步处理（异步处理必须通过中间件[redux-thunk](https://github.com/gaearon/redux-thunk),因为store.dispath(action)仅仅是简单的调用了reducer方法，而reducer要求action必须是一个普通对象不能是function）。
 
#### Redux 学习

上面只是简单Redux的介绍，关于具体学习推荐几个网址：

* [redux官网](http://redux.js.org)
* [redux中文](http://cn.redux.js.org)
* [redux的人门教程请参考教程项目](https://github.com/happypoulp/redux-tutorial)

学习的话建议还是先将官网文档过一遍，然后把文档中的例子以及后面教程的例子完全搞懂


#### React－Redux

了解了React和Redux，那么怎么将两者结合起来呢。其实有心的读者应该已经知晓，无非是将Redux的View换成React，因为React本身就是View层嘛。其实React和Redux结合无非是要解决两个问题：

* 如何在React层中拿到Redux的store，进而可以通过store去分发action
* 如何在Redux的state发生变化时候通知React，并且Redux－state数据和React props以及组件内state数据的绑定(当redux state发生变化时候，react相应绑定的state发生变化)

[react-redux](https://github.com/reactjs/react-redux)解决了这两个问题，具体结合方式看一个图

 ![React-Redux结构](http://www.pffair.com/images/56.png)
 
 [react-redux](https://github.com/reactjs/react-redux)通过Provider解决了第一个问题。Provider其实是一个经过封装的React组件，它会将redux的store传递给所有子组件；如果将Provider作为React应用最外层组件，那么整个应用的全部组件都会拿到store。根据图也能很清晰看到这点。
 
 [react-redux](https://github.com/reactjs/react-redux)通过connect解决了第二个问题。它将redux的state数据和react的props做了绑定，并且包装了action creator用于响应用户的操作，同时通过观察者模式监听了redux state数据变化并自动调用了react的setState。
 
 具体的细节推荐大家看下[文档](https://github.com/reactjs/react-redux/blob/master/docs/api.md)

有一个[react-redux的人门教程](https://github.com/lewis617/react-redux-tutorial)也不错。