//
//  CSSPrettyPrinted.h
//  CSSPrettyPrinted
//
//  Created by Joslyn Wu on 2018/2/2.
//  Copyright © 2018年 joslyn. All rights reserved.
//
// 一个带层级标记的支持中文的控制台打印。
// https://github.com/JoslynWu/CSSPrettyPrinted
//
/**
 Example:
 {
 .   set =
 .   (
 .   .   "22",
 .   .   "set 中文",
 .   .   {
 .   .   .   url = "https://www.baidu.com",
 .   .   .   title = "2子标题"
 .   .   }
 .   .   [
 .   .   .   "1item1",
 .   .   .   "1元素2",
 .   .   .   "1item3"
 .   .   ]
 .   .   "11"
 .   )
 .   itemData = <6e6f726d 616c20e6 99aee980 9a>,
 .   name = "CSSPrettyPrinted",
 .   date = 2018-04-21 10:04:26 +0000
 }
 
 - 调用css_debugSting会输出该格式。
 
 - 默认Debug时的po命令，会输出该格式。另有一下两条说明
 - 1. 若对象为NSDictionary、NSArray或者NSSet，则无其它条件。
 - 2. 若对象为普通对象，请参考css_customToJsonObjectSelector属性说明
 */


#import <Foundation/Foundation.h>

@interface NSObject (CSSPrettyPrinted)

/** 输出如Example中的log */
@property (nonatomic, strong, readonly) NSString *css_debugSting;

/**
 自定义的普通对象转JSON对象的SEL。
 
 - 该属性为类属性
 - 若对象为NSDictionary、NSArray或者NSSet，则默认无需指定。
 - 若项目中已经导入了YYModel、MJExtension或者CSSModel,则无需指定。
 - 否则，需要指定一个转JSON对象的方法。优先级 > 默认第三方支持的
 */
@property (nonatomic, assign, class) SEL css_customToJsonObjectSelector;

@end

