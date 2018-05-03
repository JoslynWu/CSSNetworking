//
//  BaseOperation.h
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CSSOperation;

typedef NSString *CSSOperationType;
extern CSSOperationType const kCSSOperationTypeSingleton;
extern CSSOperationType const kCSSOperationTypeSerial;
extern CSSOperationType const kCSSOperationTypeConcurrent;

typedef void (^CSSOperationBlock)(CSSOperation *make);

@interface CSSOperation : NSOperation

/**
 便捷构造器
 - 默认构造器的`operationType`为`kCSSOperationTypeConcurrent`
 */
- (instancetype)initWithOperationType:(CSSOperationType)type NS_DESIGNATED_INITIALIZER;

/** 操作是否在执行中 */
@property (assign, nonatomic, getter = isExecuting) BOOL executing;

/** 操作是否执行完成。（当前操作完成的标记，应该在合适的时候改变其状态） */
@property (assign, nonatomic, getter = isFinished) BOOL finished;

/**
 操作队列类型
 - kCSSOperationTypeSingleton 单例单列（非常规单例）。第一操作会被执行，随后操作被取消。
 - kCSSOperationTypeSerial 串行队列
 - kCSSOperationTypeConcurrent 并发队列
 */
@property (nonatomic, copy) CSSOperationType operationType;

/**
 主线程执行的block
 - 优先级高于 `blockOnCurrentThread`
 */
@property (nonatomic, copy) CSSOperationBlock blockOnMainThread;

/**
 当前队列所在线程的block
 - 优先级低于`blockOnMainThread`
 */
@property (nonatomic, copy) CSSOperationBlock blockOnCurrentThread;

@end

