# CSPrettyPrinted

你是否需要一种log，

**它支持中文，而不是中文Unicode;**

**它支持缩进，并且还带缩进标记符;**

**它变化不大，但总觉得更美。**

就像这样：

```
{
.   null = <null>,
.   normalStr = "normal 普通",
.   arr = 
.   [
.   .   "item1",
.   .   "元素2",
.   .   2222,
.   .   <null>,
.   .   {
.   .   .   title = "1子标题",
.   .   .   itemDictStr = "{"url": "ddd", "title": "2子标题"}",
.   .   .   url = "https://baidu.com",
.   .   .   sub = 
.   .   .   {
.   .   .   .   set = 
.   .   .   .   (
.   .   .   .   .   "22",
.   .   .   .   .   "set 中文",
.   .   .   .   .   {
.   .   .   .   .   .   url = "https://baidu.com",
.   .   .   .   .   .   title = "2子标题"
.   .   .   .   .   }
.   .   .   .   .   "11"
.   .   .   .   )
.   .   .   .   value = NSSize: {50, 50},
.   .   .   .   itemData = <6e6f726d 616c20e6 99aee980 9a>,
.   .   .   .   arr = 
.   .   .   .   [
.   .   .   .   .   "item1",
.   .   .   .   .   "元素2",
.   .   .   .   .   "item3"
.   .   .   .   ]
.   .   .   .   date = 2018-02-05 06:53:27 +0000
.   .   .   }
.   .   .   obj = <CSSimpleModel: 0x604000246ff0>
.   .   }
.   ]
.   name = "aaa",
.   numb = 2222,
.   summary = "摘要"
}
```

## 使用

**代码中:**
导入头文件，然后使用`cs_debugSting`即可。

```Objective-C
instance.cs_debugSting;
```

**控制台：**

```Objective-C
po instance
```

注意：`instance` 是 `NSDictionary` 、 `NSArray` 、 `NSSet` 的实例。


## 引入

方式一、 直接将Sources文件夹下文件添加（拖入）到项目中

```Objective-C
CSPrettyPrinted.h
CSPrettyPrinted.m
```

方式二、 CocoaPods

```Objective-C
pod 'CSPrettyPrinted'
```

## 其它

一、如果需要在使用`%@`时打印这样的格式，可以在对应的分类中添加如下代码：

```Objective-C
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
    return [NSString stringWithFormat:@"\n%@\n%@", [super description], self.cs_debugSting];
}
```

二、如果你想让所有的对象都可以使用这样打印。那么这里有一个建议：

步骤：

1、使用现在项目中的转模型工具，将对象转为`NSDictionary`（或者`NSArray`）。

2、在`NSObject`的分类中添加类似的方法实现。