# CSSOperation
NSOperation的一个扩展。便于控制任务（模块）执行顺序和方式。

### 业务场景
有多个消息弹框或者活动弹框的时候，我们希望用户能够依次看到。你可以运行该Demo点击右上角 Next 进入到下一页，查看效果。    

### 介绍
- 核心代码来自[IOSDelpan/OperationAbstract](https://github.com/IOSDelpan/OperationAbstract)，该仓库只做了简单修改，便于轻量应用。
- 核心思路：通过`NSOperation`来控制事务的依赖。通过`NSOperationQueue`控制事务执行顺序。通过扩展`NSOperation`使其更具面向对象的能力。

### 使用  

#### cocoapods

```
pod 'CSSOperation'
```

#### 手动
将CSSOperation文件移至自己项目。

### 其它
- 简单使用的时，只需要按照 demo 直接使用`CSSOperation`即可。
- 可以继承`CSSOperation`实现更模块化的事务。具体可参考原库（下面有链接）。

### 感谢
感谢[Delpan](https://www.jianshu.com/p/bc05e9ff203f)。更多扩展请参看[IOSDelpan/OperationAbstract](https://github.com/IOSDelpan/OperationAbstract)
