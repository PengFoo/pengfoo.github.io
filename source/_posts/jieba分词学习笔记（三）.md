title: jieba分词学习笔记（三）
tags:
  - dag
  - dp
  - jieba分词
  - nlp
  - 有向无环图
  - 自然语言处理
categories:
  - NLP
date: 2015-11-30 00:02:00
---


本文主要讲解有向无环图DAG在jieba分词中的应用和其利用dp进行最大概率路径的查找。

---

<!-- toc -->

---

# DAG（有向无环图）

有向无环图，directed acyclic graphs，简称DAG，是一种图的数据结构，其实很naive，就是没有环的有向图\_(:з」∠)_

DAG在分词中的应用很广，无论是最大概率路径，还是后面套NN的做法，DAG都广泛存在于分词中。

因为DAG本身也是有向图，所以用邻接矩阵来表示是可行的，但是jieba采用了python的dict，更方便地表示DAG，其表示方法为:
```
{prior1:[next1,next2...,nextN]，prior2:[next1',next2'...nextN']...}
```
以句子 "国庆节我在研究结巴分词"为例，其生成的DAG的dict表示为：
```
{0: [0, 1, 2], 1: [1], 2: [2], 3: [3], 4: [4], 5: [5, 6], 6: [6], 7: [7, 8], 8: [8], 9: [9, 10], 10: [10]}

其中，

国[0] 庆[1] 节[2] 我[3] 在[4] 研[5] 究[6] 结[7] 巴[8] 分[9] 词[10]
```
get\_DAG()函数代码如下：
```python
def get_DAG(self, sentence):
        self.check_initialized()
        DAG = {}
        N = len(sentence)
        for k in xrange(N):
            tmplist = []
            i = k
            frag = sentence[k]
            while i < N and frag in self.FREQ:
                if self.FREQ[frag]:
                    tmplist.append(i)
                i += 1
                frag = sentence[k:i + 1]
            if not tmplist:
                tmplist.append(k)
            DAG[k] = tmplist
        return DAG
```

frag即fragment，可以看到代码循环切片句子，FREQ即是词典的{word:frequency}的dict

因为在载入词典的时候已经将word和word的所有前缀加入了词典，所以一旦frag not in FREQ，即可以断定frag和以frag为前缀的词不在词典里，可以跳出循环。

由此得到了DAG，下一步就是使用dp动态规划对最大概率路径进行求解。

# 最大概率路径

值得注意的是，DAG的每个结点，都是带权的，对于在词典里面的词语，其权重为其词频，即FREQ[word]。我们要求得route = (w1, w2, w3 ,.., wn)，使得Σweight(wi)最大。


## 动态规划求解法

满足dp的条件有两个

- 重复子问题
- 最优子结构

我们来分析最大概率路径问题。

### 重复子问题

对于结点Wi和其可能存在的多个后继Wj和Wk，有:

```
任意通过Wi到达Wj的路径的权重为该路径通过Wi的路径权重加上Wj的权重{Ri->j} = {Ri + weight(j)} ；
任意通过Wi到达Wk的路径的权重为该路径通过Wi的路径权重加上Wk的权重{Ri->k} = {Ri + weight(k)} ；
```
即对于拥有公共前驱Wi的节点Wj和Wk，需要重复计算到达Wi的路径。


### 最优子结构

对于整个句子的最优路径Rmax和一个末端节点Wx，对于其可能存在的多个前驱Wi，Wj，Wk...,设到达Wi，Wj，Wk的最大路径分别为Rmaxi，Rmaxj，Rmaxk，有：

Rmax = max(Rmaxi,Rmaxj,Rmaxk...) + weight(Wx)

于是问题转化为

求Rmaxi, Rmaxj, Rmaxk...

组成了最优子结构，子结构里面的最优解是全局的最优解的一部分。

### 状态转移方程

由上一节，很容易写出其状态转移方程

Rmax = max{(Rmaxi,Rmaxj,Rmaxk...) + weight(Wx)}

## 代码

上面理解了，代码很简单，注意一点total的值在加载词典的时候求出来的，为词频之和，然后有一些诸如求对数的trick，代码是典型的dp求解代码。

```python
def calc(self, sentence, DAG, route):
        N = len(sentence)
        route[N] = (0, 0)
        logtotal = log(self.total)
        for idx in xrange(N - 1, -1, -1):
            route[idx] = max((log(self.FREQ.get(sentence[idx:x + 1]) or 1) -
                              logtotal + route[x + 1][0], x) for x in DAG[idx])
```