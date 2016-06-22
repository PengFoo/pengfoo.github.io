title: 'Py tricks(2): python中异常处理的陷阱'
tags:
  - python
categories:
  - python
date: 2015-12-11 05:31:00
---
<!-- toc -->

---

## python中的异常处理

python有自己的异常类和异常处理机制，大概长这个样子：
```python
try:
    # code block blablabla
except Exception, ex:
    # error handling code block blablabla
finally:
    # final handling code block blablabla
```

其中`finally`code block是可选的，也就是说仅有`try`和`except`的异常处理也是可以的。

很多语言都这样，司空见惯，习以为常。然而在python中，不是这么简单。

## 异常处理实验

下面给出了两个个简单的python异常处理的例子，`testFunc()`和`testFunc2()`函数分别是一段有finally和没有finally的程序实例。猜猜运行结果是什么样子的？

```
def raiseException():
    raise Exception("raising a Exception")

def testFunc():
    try:
        raiseException()
        # blablabla
        return "prog running ok"
    except Exception, ex:
        return "prog running error"


def testFunc2():
    try:
        raiseException()
        # blablabla
        return "prog running ok"
    except Exception, ex:
        return "prog running error"
    finally:
        return "prog running finished"


if __name__ == '__main__':
    print testFunc()
    print testFunc2()

```

按照其他语言的性格，两个testFunc()输出结果应该是一样的`prog running error`，但是Python的输出结果是：
```
prog running error
prog running finished

Process finished with exit code 0

```
只有try...except...的testFunc输出了prog running error，而拥有try...except...finally...的testFunc2输出了prog running finished。



## 解释

python的异常处理机制与其他语言不同，在异常处理中，如果存在finally语句，python认为finally语句是异常处理的一部分，对于异常的处理语句必须执行完毕，那么finally中的语句在程序能够控制的情况下一定会执行，所有try和except中的语句会被挂起不执行，从而保证finally中的语句会执行。

于是就出现了和西方的那一套截然不同的返回结果。

对于这个问题，python引以为傲，认为这是一个feature。我们在写代码中要注意，在有finally的code block中，要把return 写在finally中。
