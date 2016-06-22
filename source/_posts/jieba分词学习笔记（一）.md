title: jieba分词学习笔记（一）
tags:
  - nlp
  - jieba
  - 分词
  - 自然语言处理
categories:
  - NLP
date: 2015-11-27 22:47:00
---
<!-- toc -->
---
# 序

中科院的ICTCLAS，哈工大的ltp，东北大学的NIU Parser是学术界著名的分词器，我曾浅显读过一些ICTCLAS的代码，然而并不那么好读。jieba分词是python写成的一个算是工业界的分词开源库，其github地址为：https://github.com/fxsjy/jieba

jieba分词虽然效果上不如ICTCLAS和ltp，但是胜在python编写，代码清晰，扩展性好，对jieba有改进的想法可以很容易的自己写代码进行魔改。毕竟这样说好像自己就有能力改进jieba分词一样\_(:з」∠)_

> 网上诸多关于jieba分词的分析，多已过时，曾经分析jieba分词采用trie树的数据结构云云的文章都已经过时，现在的jieba分词已经放弃trie树，采用前缀数组字典的方式存储词典。

本文分析的jieba分词基于`2015年7月`左右的代码进行，日后jieba若更新，看缘分更新这一系列文章\_(:з」∠)_

# jieba分词的基本思路

jieba分词对已收录词和未收录词都有相应的算法进行处理，其处理的思路很简单，当然，过于简单的算法也是制约其召回率的原因之一。

其主要的处理思路如下：

1. 加载词典dict.txt
2. 从内存的词典中构建该句子的DAG（有向无环图）
3. 对于词典中未收录词，使用HMM模型的viterbi算法尝试分词处理
4. 已收录词和未收录词全部分词完毕后，使用dp寻找DAG的最大概率路径
5. 输出分词结果

# 词典的加载

## 语料库和词典

jieba分词默认的模型使用了一些语料来做训练集，在 https://github.com/fxsjy/jieba/issues/7 中，作者说


> 来源主要有两个，一个是网上能下载到的1998人民日报的切分语料还有一个msr的切分语料。另一个是我自己收集的一些txt小说，用ictclas把他们切分（可能有一定误差）。 然后用python脚本统计词频。


jieba分词的默认语料库选择看起来满随意的\_(:з」∠)_，作者也吐槽高质量的语料库不好找，所以如果需要在生产环境使用jieba分词，尽量自己寻找一些高质量的语料库来做训练集。

语料库中所有的词语被用来做两件事情：
1. 对词语的频率进行统计，作为登录词使用
2. 对单字在词语中的出现位置进行统计，使用BMES模型进行统计，供后面套HMM模型Viterbi算法使用，这个后面说。

统计后的结果保存在dict.txt中，摘录其部分结构如下：
```
上访 212 v
上访事件 3 n
上访信 3 nt
上访户 3 n
上访者 5 n
上证 120 j
上证所 8 nt
上证指数 3 n
上证综指 3 n
上诉 187 v
上诉书 3 n
上诉人 3 n
上诉期 3 b
上诉状 4 n
上课 650 v
```

其中，`第一列是中文词语`，`第二列是词频`，第三列是词性，jieba分词现在的版本除了分词也提供词性标注等其他功能，这个不在本文讨论范围内，可以忽略第三列。jieba分词所有的统计来源，就是这个语料库产生的两个模型文件。

## 对字典的处理

jieba分词为了快速地索引词典以加快分词性能，使用了前缀数组的方式构造了一个dict用于存储词典。

在旧版本的jieba分词中，jieba采用trie树的数据结构来存储，其实对于python来说，使用trie树显得非常多余，我将对新老版本的字典加载分别进行分析。

### trie树

#### trie树简介

trie树又叫字典树，是一种常见的数据结构，用于在一个字符串列表中进行快速的字符串匹配。其核心思想是将拥有公共前缀的单词归一到一棵树下以减少查询的时间复杂度，其主要缺点是占用内存太大了。

trie树按如下方法构造：
- trie树的根节点是空，不代表任何含义
- 其他每个节点只有一个字符，词典中所有词的第一个字的集合作为第一层叶子节点，以字符α开头的单词挂在以α为根节点的子树下，所有以α开头的单词的第二个字的集合作为α子树下的第一层叶子节点，以此类推
- 从根节点到某一节点，路径上经过的字符连接起来，为该节点对应的字符串

一个以`and at as cn com`构造的trie树如下图：

![trie tree](http://7xn47m.com1.z0.glb.clouddn.com/2012112521092438.png)

查找过程如下：

- 从根结点开始一次搜索；
- 取得要查找关键词的第一个字母，并根据该字母选择对应的子树并转到该子树继续进行检索；
- 在相应的子树上，取得要查找关键词的第二个字母,并进一步选择对应的子树进行检索。
- 迭代过程……
- 在某个结点处，关键词的所有字母已被取出，则读取附在该结点上的信息，即完成查找。其他操作类似处理.

如查询at，可以找到路径`root-a-t`的路径，对于单词av，从root找到a后，在a的叶子节点下面不能找到v结点，则查找失败。


trie树的查找时间复杂度为O(k)，k = len(s)，s为目标串。

二叉查找树的查找时间复杂度为O(lgn)，比起二叉查找树，trie树的查找和结点数量无关，因此更加适合词汇量大的情况。

但是trie树对空间的消耗是很大的，是一个典型的空间换时间的数据结构。

#### jieba分词的trie树

旧版本jieba分词中关于trie树的生成代码如下：
```python
def gen_trie(f_name):  
    lfreq = {}  
    trie = {}  
    ltotal = 0.0  
    with open(f_name, 'rb') as f:  
        lineno = 0   
        for line in f.read().rstrip().decode('utf-8').split('\n'):  
            lineno += 1  
            try:  
                word,freq,_ = line.split(' ')  
                freq = float(freq)  
                lfreq[word] = freq  
                ltotal+=freq  
                p = trie  
                for c in word:  
                    if c not in p:  
                        p[c] ={}  
                    p = p[c]  
                p['']='' #ending flag  
            except ValueError, e:  
                logger.debug('%s at line %s %s' % (f_name,  lineno, line))  
                raise ValueError, e  
    return trie, lfreq, ltotal  
```

代码很简单，遍历每行文件，对于每个单词的每个字母，在trie树（trie和p变量）中查找是否存在，如果存在，则挂到下面，如果不存在，就建立新子树。

jieba分词采用python 的dict来存储树，这也是python对树的数据结构的通用做法。

我写了一个函数来直观输出其生成的trie树，代码如下：

```python

def print_trie(tree, buff, level = 0, prefix=''):
    count = len(tree.items())
    for k,v in tree.items():
        count -= 1
        buff.append('%s +- %s' % ( prefix , k if k!='' else 'NULL'))
        if v:
            if count  == 0:
                print_trie(v, buff, level + 1, prefix + '    ')
            else:
                print_trie(v, buff, level + 1, prefix + ' |  ')
        pass
    pass

trie, list_freq, total =  gen_trie('a.txt')
buff = ['ROOT']
print_trie(trie, buff, 0)
print('\n'.join(buff))

```

使用上面列举出的dict.txt的部分词典作为样例，输出结果如下
```
ROOT
 +- 上
     +- 证
     |   +- NULL
     |   +- 所
     |   |   +- NULL
     |   +- 综
     |   |   +- 指
     |   |       +- NULL
     |   +- 指
     |       +- 数
     |           +- NULL
     +- 诉
     |   +- NULL
     |   +- 人
     |   |   +- NULL
     |   +- 状
     |   |   +- NULL
     |   +- 期
     |   |   +- NULL
     |   +- 书
     |       +- NULL
     +- 访
     |   +- NULL
     |   +- 信
     |   |   +- NULL
     |   +- 事
     |   |   +- 件
     |   |       +- NULL
     |   +- 者
     |   |   +- NULL
     |   +- 户
     |       +- NULL
     +- 课
         +- NULL
```

#### 使用trie树的问题

本来jieba采用trie树的出发点是可以的，利用空间换取时间，加快分词的查找速度，加速全切分操作。但是问题在于python的dict原生使用哈希表实现，在dict中获取单词是近乎O(1)的时间复杂度，所以使用trie树，其实是一种避重就轻的做法。

于是2014年某位同学的PR修正了这一情况。

### 前缀数组

在2014年的某次PR中（https://github.com/fxsjy/jieba/pull/187 ），提交者将trie树改成前缀数组，大大地减少了内存的使用，加快了查找的速度。

现在jieba分词对于词典的操作，改为了一层word:freq的结构，存于lfreq中，其具体操作如下：

1. 对于每个收录词，如果其在lfreq中，则词频累积，如果不在则加入lfreq
2. 对于该收录词的所有前缀进行上一步操作，如单词'cat'，则对c, ca, cat分别进行第一步操作。除了单词本身的所有前缀词频初始为0.

```python
def gen_pfdict(self, f):
        lfreq = {}
        ltotal = 0
        f_name = resolve_filename(f)
        for lineno, line in enumerate(f, 1):
            try:
                line = line.strip().decode('utf-8')
                word, freq = line.split(' ')[:2]
                freq = int(freq)
                lfreq[word] = freq
                ltotal += freq
                for ch in xrange(len(word)):
                    wfrag = word[:ch + 1]
                    if wfrag not in lfreq:
                        lfreq[wfrag] = 0
            except ValueError:
                raise ValueError(
                    'invalid dictionary entry in %s at Line %s: %s' % (f_name, lineno, line))
        f.close()
        return lfreq, ltotal

```

很朴素的做法，然而充分利用了python的dict类型，效率提高了不少。