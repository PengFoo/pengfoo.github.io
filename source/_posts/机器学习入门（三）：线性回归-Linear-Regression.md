title: 机器学习入门（三）：线性回归--Linear Regression
tags:
  - ML
  - Machine Learning
  - 机器学习
  - 线性回归
  - Linear Regression
categories: []
date: 2016-01-31 23:16:00
---
<!-- toc -->
----

## Linear Regression in one sentence

Linear Regression用于拟合一条线性直线，但不能叫它LR，因为LR被另一个应用更为广泛的Logistic Regression抢走了。

事实上有许多方法能做同样的事情，比如高中就学过的最小二乘法。比起他们，这一篇文章更具现实性意义的地方在于，用简单的例子阐明一些机器学习常见的问题，比如
- 一般形式的model representation
- 用cost function（又称loss function）来标定假设函数的好坏
- 用gradient decent（梯度下降，有时使用gradient accent，梯度上升）来寻找全局/局部最优解
- 理解supervised learning（监督学习）的基本形式
- feature scaling对学习速率的影响
- ....


## 机器学习中的线性回归

线性回归不是一个难理解的问题，如下图，就是一个典型的二维的线性回归问题，即使推广到高维，这个问题也是不难理解的。

![一个线性回归模型的示意图][1]

不过在机器学习问题中，我们有一些约定的称呼和惯用语：

|Before|After|
|------|------|
|自变量|特征 (feature)|
|解析式 　$f(x)$　  |Hypothesis 　$h(x)$　	|
|系数|参数 (parameter)或权重(weight)|

在机器学习中，通常把自变量叫做特征，对于多个自变量，即多个特征，通常用一个特征向量　$x = (x\_1,x\_2,\\ldots,x\_n)$　表示特征们。

在机器学习中，通常把回归方程（ 这里以一个`二元一次方程`为例）　$y = a\_1x\_1 + a\_2x\_2 + b$　的系数和截距　$(a\_1,a\_2,b)$　结合起来，叫做参数或权重，经常　用$\theta$　或$　w$表示，参数或权重也是一个向量。特别地，在神经网络等模型中，截距b也会单独拿出来，此时截距叫做偏置(bias)。

对于已知的用来进行回归的数据的集合，在机器学习中统一称为训练集（training set），最终得到的解析式通常用符号　$h\_\theta(x)$　	表示，叫做以用 　$\theta$　为参数的模型的hypothesis（假说）。

对于`一元线性回归`，其　$h\_\theta(x)$　	的形式可能如下：
$$h\_\theta(x) = \theta\_0 + \theta\_1x $$
其中，$\theta\_0$,$\theta\_1$是参数向量的两个分量。

我们追求更美和更易于计算的表现形式，有时我们会为常数项bias加一个值恒为1的$x\_0$，然后把$x\_0$并入x特征向量中，此时特征向量变为$x = (x\_0,x\_1,x\_2,\\ldots,x\_n)$，此时　$h\_\theta(x)$　变得更美：

$$h\_\theta(x) = \theta x $$


> 类似这样简化公式表现形式的trick在其他模型的representation也经常会碰到，它不仅仅让表现形式变得更美， 也让计算变得更简洁。



## Cost Function/Loss Function

对于一个已有的hypothesis，我们需要有方法来对假说进行评估，来判断假说的好坏，cost function也叫作loss function，就是对假说进行评估的一个函数。通常来说，模型越准确，越接近真实，其cost function的值就越小。

对于loss function，有一篇文章写的话很好。[\[machine learning\] Loss Function view](http://eletva.com/tower/?p=186)，这篇文章对loss function 写得比较全面，看不懂也没关系，不同的loss function，我们将在不同的算法和模型中遇到，loss function 通常用大写字母J表示，由于loss function的大小和hypothesis的参数取值相关，不难想象，J是$\theta$的函数，用$J\_\theta$表示。

### 线性回归的cost function

在线性回归问题中，通常使用square loss的形式。线性回归常用的square loss形式是均方误差MSE：

$$ J\_\theta = \frac\{1\}\{m\} \left( h\_\theta (x^{(i)}) - y^{(i)} \right)^2 $$

这里x和y的右上角标i，表示training set中第i个数据的特征向量和实际值，加括号表示是第i个，而不是i次幂。

通常，也有如下的表示形式：


$$ J\_\theta = \frac\{1\}\{2m\} \left( h\_\theta (x^{(i)}) - y^{(i)} \right)^2 $$

这样做是方便后面求偏导数的时候约掉偏导数系数中的2，更方便计算。

由loss function 可以得知，当hypothesis 对training set测试结果完全正确的时候，loss function的值是0。

而我们的目标，就是尽量优化hypothesis，不断更改$\theta$的值，使得$J\_\theta$的值最小，即

$$ \mathop{Minimize}\limits_{\theta} J(\theta)$$

### 对Cost Function的解读

至此，cost function仍稍显抽象，好在Linear Regression问题的cost function 是一个二次函数，图像是好画的，我们尝试从图像理解cost function和对cost function 求解权重向量的目标。

下面我们以一元一次回归方程的cost function $$ J\_\theta = \frac\{1\}\{2m\} \left( h\_\theta (x^{(i)}) - y^{(i)} \right)^2 $$为例。

我们注意到$J(\theta)$是一个二次函数，cost function有两个未知数$\theta\_0$和$\theta\_1$，固定一个参，$\theta\_0$时，$J(\theta)是$\theta\_1$的二次函数，其图像应该是一个抛物线。可能长得如下图所示：

![cost function一个分量的图像][3]

注意到曲线的全局极值是大于等于0的，当且仅当training set能够完美拟合成一条直线的时候，抛物线的极值才会触到x轴上。

类似的，$J(\theta)$和$\theta\_0$的图像也是这样一条抛物线曲线。

如果综合两个参数$\theta\_0$和$\theta\_1$，其曲线可能长这个样子：

![cost function的图像][4]

其全局极值点的坐标，就是我们要求的权重向量$\theta$。



## 阶段总结

到现在为止，我们已经把一个问题抽象成机器学习喜闻乐见的形式：

![Linear Regression的问题描述][2]

> 一般地，对于机器学习问题，我们都要这样，确定hypothesis，cost function和goal，通常对cost function 求解权重向量的过程，是一个最优化问题。

## Gradient Decent（梯度下降）

对于二次函数，我们可以简单的求偏导求极值点来进行极值的求解，但是更多时候，我们遇见的情况并不那么好直接求出全局极值的代数解，于是我们使用梯度下降的方式来进行全局极值的逼近。（如果是求极大值，那么相应的方法就叫做梯度上升，gradient accent）

梯度即函数下降最快的方向，在数值上等于函数在该点的导数。沿着梯度方向走，总能找到局部极值，如图，是从函数某一点，沿梯度下降的一个例子。

![梯度下降的一个例子][5]

但是gradient decent 有一个问题，按照梯度方向，只能找到相应的局部极值，并不能确定找到的局部极值就是全局极值，而且从不同的点出发，沿梯度下降找到的局部极值可能不同。如下图，从两个不同的点出发，最终滑向不同的极值点。

![不同极值的一个例子][6]

这一点时要注意的，虽然梯度下降对于任意可导函数都可以使用，但是可能得到的结果并不如人意是全局极值，我们可能只能得到全局极值的近似解。要一定得到全局最值，可以考虑：

- 将函数近似成凸函数
- 在能接受的时间内在尽量大的scale内多取点进行gradient decent
- 使用一些方法来概率性地跳出局部极值

不过，这些不在今天的讨论范围内。

### 梯度下降的两个参数

一般地，梯度下降有两个问题需要考虑：

1. 一次下降多少？
2. 如何定义下降停止的条件？

第一个问题在gradient decent中叫做学习速率，learning rate的选取，第二个问题叫做终止条件的确定。

#### learning rate的选取

learning rate不应该太大，也不应该太小，如图所示：

![不同极值的一个例子][7]

- 如果learning rate 太大，可能导致梯度下降的过程会来回震荡，不能命中极值点
- 如果learning rate 太小，有两个问题：
	- 可能导致梯度下降陷在某一小段极值中不能跳出
	- 可能导致到达极值的迭代次数过多，学习时间过于缓慢

因此tuning learning rate是机器学习问题经常要遇到的问题之一。


#### 终止条件

一般来讲，终止条件可以综合选择：

- 指定次数，比如上限100000次
- 相邻两次gradient decent的差的阈值

### 使用梯度下降更新参数值

使用梯度下降更新参数值使用如下的步骤：

![使用梯度下降更新参数值][8]

其中一次梯度更新要注意，需要同时更新所有参数的值，而不能更新一个之后再更新另一个，会跑偏。

![使用梯度下降更新参数值的正误对比][9]

### Batch Gradient Decent

在这个case中，我们使用的gradient decent是每次做gradient decent的时候都利用了所有的数据点进行cost function的偏导数的计算，这样的gradient decent叫做batch gradient decent。尽管batch gradient decent是最可靠的，但是数据量巨大的时候，这个方法显得太耗时间。

在其他的模型中，我们可能遇到其他方法进行gradient decent，如随机梯度下降等，在速度和精确度之间进行了衡量和妥协。

### Linear Regression的梯度下降

到`阶段总结`章节为止，我们抽象了Linear Regression的数学问题表达形式、确定了loss function并确定了最优化目标，在这一章节，我们来计算如何使用梯度下降进行Linear Regression问题的最优化问题求解。

至此，我们拥有这样的阶段性成果：

![阶段性成果][10]

对$j=0$和$j=1$的$\theta\_j$分别求偏导，易得：
{% raw %}
$$\frac {\partial} {\partial \theta_0} J(\theta_0,\theta_1) = \frac{1} {m} \sum_{i=1}^{m}\left( h_\theta(x^{(i)}) - y^{(i)}\right)$$

$$\frac {\partial} {\partial \theta_1} J(\theta_0,\theta_1) = \frac{1} {m} \sum_{i=1}^{m}\left( h_\theta(x^{(i)}) - y^{(i)}\right)x^{(i)}$$

{% endraw %}

那么，对线性回归相应的gradient decent algorithm就是如下的：

![linear regression的gradient decent][11]

而对于初始的$\theta\_j$的值，我们通常选择随机选取的方式，反正无论如何，gradient decent总会找到一个局部极值的。

下图展示了gradient decent 在linear regression中发挥的神奇作用，左图是参数对应的函数图像，右图是cost function的等高线图，可以看到，在随机的错误离谱的参数值前提下，经过若干轮gradient decent，最后成功得到cost function 局部极值对应的hypothesis。

![linear regression的gradient decent的gif][12]



[1]: http://7xn47m.com1.z0.glb.clouddn.com/3.jpg
[2]: http://7xn47m.com1.z0.glb.clouddn.com/rep.jpg
[3]: http://7xn47m.com1.z0.glb.clouddn.com/cost_function.jpg
[4]: http://7xn47m.com1.z0.glb.clouddn.com/cf.jpg
[5]: http://7xn47m.com1.z0.glb.clouddn.com/QQ%E6%88%AA%E5%9B%BE20160206195927.jpg
[6]: http://7xn47m.com1.z0.glb.clouddn.com/QQ%E6%88%AA%E5%9B%BE20160206200128.jpg
[7]: http://7xn47m.com1.z0.glb.clouddn.com/QQ%E6%88%AA%E5%9B%BE20160206201833.jpg
[8]: http://7xn47m.com1.z0.glb.clouddn.com/QQ%E6%88%AA%E5%9B%BE20160206205130.jpg
[9]: http://7xn47m.com1.z0.glb.clouddn.com/QQ%E6%88%AA%E5%9B%BE20160206205138.jpg
[10]: http://7xn47m.com1.z0.glb.clouddn.com/QQ%E6%88%AA%E5%9B%BE20160206205508.jpg
[11]: http://7xn47m.com1.z0.glb.clouddn.com/QQ%E6%88%AA%E5%9B%BE20160206213442.jpg
[12]: http://7xn47m.com1.z0.glb.clouddn.com/gd.gif