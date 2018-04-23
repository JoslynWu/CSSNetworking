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
 .   .   .   url = "https://baidu.com",
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
 */

#import <Foundation/Foundation.h>


@interface NSDictionary (CSSPrettyPrinted)

@property (nonatomic, strong, readonly) NSString *css_debugSting;

@end


@interface NSArray (CSSPrettyPrinted)

@property (nonatomic, strong, readonly) NSString *css_debugSting;

@end


@interface NSSet (CSSPrettyPrinted)

@property (nonatomic, strong, readonly) NSString *css_debugSting;

@end
