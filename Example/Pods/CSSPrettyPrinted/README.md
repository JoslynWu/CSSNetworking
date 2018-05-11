# CSSPrettyPrinted

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
.   .   .   obj = <CSSSimpleModel: 0x604000246ff0>
.   .   }
.   ]
.   name = "aaa",
.   numb = 2222,
.   summary = "摘要"
}
```

## 功能

- 支持中文打印
- 带缩进标记
- `po`命令默认支持


## 使用

**代码中:**
导入头文件，然后使用`css_debugSting`即可。

```Objective-C
instance.css_debugSting;
```

**控制台：**

```Objective-C
po instance
```


## 引入

方式一、 直接将Sources文件夹下文件添加（拖入）到项目中

```Objective-C
CSSPrettyPrinted.h
CSSPrettyPrinted.m
```

方式二、 CocoaPods

```Objective-C
pod 'CSSPrettyPrinted'
```

## 说明

- 如果使用了`YYModel`、`MJExtension`或者`CSSModel`，普通对象同样被支持。
- 如果没有使用者三种转模型，那么可以通过`css_customToJsonObjectSelector`指定自定义的方式。

## 其它

- 如果需要在使用`%@`时打印这样的格式，可以添加如下代码：
`NSDictionary`、`NSArray`和`NSSet`需要添加到对应的分类中

```Objective-C
- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p>\n%@",NSStringFromClass([self class]), self, self.css_debugSting];
}
```

