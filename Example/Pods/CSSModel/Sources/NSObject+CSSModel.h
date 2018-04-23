//
//  NSObject+CSSModel.h
//  CSSModel
//
//  Created by Joslyn Wu on 2018/1/21.
//  Copyright © 2018年 joslyn. All rights reserved.
//
//  一个简约的转Model工具
// https://github.com/JoslynWu/CSSModel
// - 默认支持解归档（NSKeyedArchiver/NSKeyedUnarchiver）

#import <Foundation/Foundation.h>

/**
 构造空协议
 */
#define CSSModelProtocol(modelName) \
@protocol modelName \
@end

NS_ASSUME_NONNULL_BEGIN
@interface NSObject (CSSModel)<NSSecureCoding>

/**
 深度clone (deep copy)
 - 所有层级的地址均被复制

 @return clone后的对象
 */
- (instancetype)css_clone;

/**
 转Moddel方法
 - 支持符合JSON格式的NSDictionary、NSData和NSString
 - 模型中的NSArray类型，需要指定以元素为名称的协议。（e.g. xxModel<xxElement>）

 @param json json数据
 @return 解析后的对象
 */
+ (instancetype)css_modelWithJson:(id)json;

/**
 将顶级节点为Array的Json转换为模型数组

 @param array 顶级节点为Array的Json
 @return 模型数组
 */
+ (NSArray *)css_modelsWithArray:(NSArray *)array;

/**
 Model 转 NSDictionary
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, id> *css_modelToDictionary;

/**
 一个便于Debug的控制台打印。
 - 更多：https://github.com/JoslynWu/CSSPrettyPrinted
 */
@property (nonatomic, strong, readonly) NSString *css_debugSting;

@end
NS_ASSUME_NONNULL_END
