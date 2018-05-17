//
//  BaseOperation.h
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//
// https://github.com/JoslynWu/CSSOperation
//

#import <Foundation/Foundation.h>
#import "NSOperation+CSSOperation.h"

@class CSSOperation;

typedef NSString *CSSOperationType;
extern CSSOperationType const kCSSOperationTypeSingleton;
extern CSSOperationType const kCSSOperationTypeSerial;
extern CSSOperationType const kCSSOperationTypeConcurrent;

typedef void (^CSSOperationBlock)(__kindof CSSOperation *maker);

NS_ASSUME_NONNULL_BEGIN
@interface CSSOperation : NSOperation

/**
 指定构造器
 - 你可以使用默认构造创建实例，然后再修改`operationType`
 - 默认构造器(-init)的`operationType`默认为`kCSSOperationTypeConcurrent`
 */
- (instancetype)initWithOperationType:(CSSOperationType)type NS_DESIGNATED_INITIALIZER;

/** 便捷构造器 */
+ (instancetype)operationWithType:(CSSOperationType)type;

/** 操作是否在执行中 */
@property (assign, nonatomic, getter=isExecuting) BOOL executing;

/** 操作是否执行完成。（当前操作完成的标记，应该在合适的时候改变其状态） */
@property (assign, nonatomic, getter=isFinished) BOOL finished;

/**
 操作队列类型
 - kCSSOperationTypeSingleton 单例队列（伪单例）。第一操作会被执行，随后操作被取消。
 - kCSSOperationTypeSerial 串行队列
 - kCSSOperationTypeConcurrent 并发队列
 */
@property (nonatomic, copy) CSSOperationType operationType;

/**
 主线程执行的block
 - 优先级高于 `blockOnCurrentThread`
 */
@property (nonatomic, copy, nullable) CSSOperationBlock blockOnMainThread;

/**
 当前队列所在线程的block
 - 优先级低于`blockOnMainThread`
 */
@property (nonatomic, copy, nullable) CSSOperationBlock blockOnCurrentThread;

/**
 自定义的操作队列
 - 根据`operationType`进入对应的队列
 - 默认为nil。默认情况下会根据`operationType`创建全局队列，与APP的生命周期相同。
 - 一般情况下无需指定该属性，除非你想隔离操作。
 */
@property (nonatomic, strong, nullable) NSDictionary<CSSOperationType, __kindof NSOperationQueue *> *queues;

@end
NS_ASSUME_NONNULL_END

