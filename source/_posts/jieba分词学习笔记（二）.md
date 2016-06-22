title: jieba分词学习笔记（二）
tags:
  - jieba
  - nlp
  - 分词
  - 自然语言处理
categories:
  - NLP
date: 2015-11-28 21:36:00
---
<!-- toc -->
---
# 分词模式

jieba分词有多种模式可供选择。可选的模式包括：
- 全切分模式
- 精确模式
- 搜索引擎模式

同时也提供了HMM模型的开关。

其中全切分模式就是输出一个字串的所有分词，

精确模式是对句子的一个概率最佳分词，

而搜索引擎模式提供了精确模式的再分词，将长词再次拆分为短词。

效果大抵如下：
```python
# encoding=utf-8
import jieba

seg_list = jieba.cut("我来到北京清华大学", cut_all=True)
print("Full Mode: " + "/ ".join(seg_list))  # 全模式

seg_list = jieba.cut("我来到北京清华大学", cut_all=False)
print("Default Mode: " + "/ ".join(seg_list))  # 精确模式

seg_list = jieba.cut("他来到了网易杭研大厦")  # 默认是精确模式
print(", ".join(seg_list))

seg_list = jieba.cut_for_search("小明硕士毕业于中国科学院计算所，后在日本京都大学深造")  # 搜索引擎模式
print(", ".join(seg_list))

```
的结果为

```
【全模式】: 我/ 来到/ 北京/ 清华/ 清华大学/ 华大/ 大学

【精确模式】: 我/ 来到/ 北京/ 清华大学

【新词识别】：他, 来到, 了, 网易, 杭研, 大厦    (此处，“杭研”并没有在词典中，但是也被Viterbi算法识别出来了)

【搜索引擎模式】： 小明, 硕士, 毕业, 于, 中国, 科学, 学院, 科学院, 中国科学院, 计算, 计算所, 后, 在, 日本, 京都, 大学, 日本京都大学, 深造
```

其中，新词识别即用HMM模型的Viterbi算法进行识别新词的结果。

值得详细研究的模式是精确模式，以及其用于识别新词的HMM模型和Viterbi算法。


# jieba.cut()
 
 
在载入词典之后，jieba分词要进行分词操作，在代码中就是核心函数`jieba.cut()`，代码如下：
```python
 def cut(self, sentence, cut_all=False, HMM=True):
        '''
        The main function that segments an entire sentence that contains
        Chinese characters into seperated words.
        Parameter:
            - sentence: The str(unicode) to be segmented.
            - cut_all: Model type. True for full pattern, False for accurate pattern.
            - HMM: Whether to use the Hidden Markov Model.
        '''
        sentence = strdecode(sentence)

        if cut_all:
            re_han = re_han_cut_all
            re_skip = re_skip_cut_all
        else:
            re_han = re_han_default
            re_skip = re_skip_default
        if cut_all:
            cut_block = self.__cut_all
        elif HMM:
            cut_block = self.__cut_DAG
        else:
            cut_block = self.__cut_DAG_NO_HMM
        blocks = re_han.split(sentence)
        for blk in blocks:
            if not blk:
                continue
            if re_han.match(blk):
                for word in cut_block(blk):
                    yield word
            else:
                tmp = re_skip.split(blk)
                for x in tmp:
                    if re_skip.match(x):
                        yield x
                    elif not cut_all:
                        for xx in x:
                            yield xx
                    else:
                        yield x
```

其中，

docstr中给出了默认的模式，精确分词 + HMM模型开启。

第12-23行进行了变量配置。

第24行做的事情是对句子进行中文的切分，把句子切分成一些只包含能处理的字符的块（block），丢弃掉特殊字符，因为一些词典中不包含的字符可能对分词产生影响。

24行中re\_han默认值为re\_han\_default，是一个正则表达式，定义如下：
```python
# \u4E00-\u9FD5a-zA-Z0-9+#&\._ : All non-space characters. Will be handled with re_han
re_han_default = re.compile("([\u4E00-\u9FD5a-zA-Z0-9+#&\._]+)", re.U)
```
可以看到诸如空格、制表符、换行符之类的特殊字符在这个正则表达式被过滤掉。

25-40行使用yield实现了返回结果是一个迭代器，即文档中所说：

> jieba.cut 以及 jieba.cut_for_search 返回的结构都是一个可迭代的 generator，可以使用 for 循环来获得分词后得到的每一个词语(unicode)

其中，31-40行，如果遇到block是非常规字符，就正则验证一下直接输出这个块作为这个块的分词结果。如标点符号等等，在分词结果中都是单独一个词的形式出现的，就是这十行代码进行的。

关键在28-30行，如果是可分词的block，那么就调用函数`cut_block`，默认是`cut_block = self.__cut_DAG`，进行分词


# jieba.__cut_DAG()


`__cut_DAG`的作用是按照DAG，即有向无环图进行切分单词。其代码如下：
```python
def __cut_DAG(self, sentence):
        DAG = self.get_DAG(sentence)
        route = {}
        self.calc(sentence, DAG, route)
        x = 0
        buf = ''
        N = len(sentence)
        while x < N:
            y = route[x][1] + 1
            l_word = sentence[x:y]
            if y - x == 1:
                buf += l_word
            else:
                if buf:
                    if len(buf) == 1:
                        yield buf
                        buf = ''
                    else:
                        if not self.FREQ.get(buf):
                            recognized = finalseg.cut(buf)
                            for t in recognized:
                                yield t
                        else:
                            for elem in buf:
                                yield elem
                        buf = ''
                yield l_word
            x = y

        if buf:
            if len(buf) == 1:
                yield buf
            elif not self.FREQ.get(buf):
                recognized = finalseg.cut(buf)
                for t in recognized:
                    yield t
            else:
                for elem in buf:
                    yield elem
```

对于一个sentence，首先 获取到其有向无环图DAG，然后利用dp对该有向无环图进行最大概率路径的计算。
计算出最大概率路径后迭代，如果是登录词，则输出，如果是单字，将其中连在一起的单字找出来，这些可能是未登录词，使用HMM模型进行分词，分词结束之后输出。

至此，分词结束。

其中，值得跟进研究的是`第2行获取DAG`，`第4行计算最大概率路径`和`第20和34行的使用HMM模型进行未登录词的分词`，在后面的文章中会进行解读。
```python
DAG = self.get_DAG(sentence)

	...

self.calc(sentence, DAG, route)

	...

recognized = finalseg.cut(buf)
```
