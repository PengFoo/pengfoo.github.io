title: 'Py tricks(1): python实现不可修改的常量'
tags:
  - python
  - python tricks
  - pythonic
categories:
  - python
date: 2015-11-25 22:28:00
---
因为种种原因，Python并未提供如C/C++/Java一样的const修饰符，换言之，python中没有常量，至少截止2015年年末，还没有这个打算。Python程序一般通过约定俗成的变量名全大写的形式来表示这是一个常量，但是这终究不是长久之计。

其实Python可以曲线救国实现常量。

在Python的面向对象中，`object.__setattr__()`这个built-in function在对类的属性赋值的时候会自动调用。其函数原型为：

```python
object.__setattr__(self, name, value)
```
其中name为变量名，value为变量值。

而`object.__dict__`则以dict的形式保存了object内所有可写的属性，key为变量名，value为变量值。

那么我们就有可能通过建立一个const类，对其`object.__setattr__()`方法进行overwrite，在对属性值进行赋值的时候判断，如果属性存在，则表示这是对常量的重赋值操作，从而抛出异常，如果属性不存在，则表示是新声明了一个常量，可以进行赋值操作。

const.py 代码如下：
```python
# -*- coding: utf-8 -*-

class _const:
    class ConstError(TypeError) : pass

    def __setattr__(self, key, value):
        # self.__dict__
        if self.__dict__.has_key(key):
            raise self.ConstError,"constant reassignment error!"
        self.__dict__[key] = value

import sys

sys.modules[__name__] = _const()

```


其中，1-10行是上述思路的类的一个实现。
第12-14行的写法值得说明。我们尽管拥有了_const类，但是我们当前使用这个类仍然需要
```python
import const

c = const._const()
c.TEST_CONSTANT = 'test'
```
这样的形式来声明一个常量TEST_CONSTANT，然而我们希望用更简洁的方法进行常量的赋值。形如：
```python
import const

const.TEST_CONSTANT = 'test'
```

在python中,`__name__`内置属性是当前的class或者type的值。通俗地讲，`__name__`的值有以下两种形式：

- 如果运行某一个py文件，在该文件中，`__name__`的值为`'__main__'`
- 如果import了某一个py文件，那么在该import的文件中，`__name__`的值为该文件的文件名(不带.py后缀)

而`sys.modules`是一个dict对象，包括了当前上下文中python已经load的所有模块的信息，dict的key为文件名，value为模块对象。

在const.py 中，14行的写法等价于

```python
import const

sys.modules['const'] = _const()
```

即，让_const类作为模块的入口点，引入const.py等价于声明了一个_const类的实例。

至此python的常量实现完毕，使用test.py测试：
```python
# -*- coding: utf-8 -*-

import const

const.TEST = 'test'
print const.TEST
const.TEST1 = 'test1'
print const.TEST1
const.TEST = 'test'
print const.TEST
```

打印信息如下：
```
test
test1
Traceback (most recent call last):
  File "H:/code/test.py", line 9, in <module>
    const.TEST = 'test'
  File "H:\code\const.py", line 9, in __setattr__
    raise self.ConstError,"constant reassigning error!"
const.ConstError: constant reassignment error!

```

成功为两常量赋值，在试图修改第一个常量值时抛出异常:)