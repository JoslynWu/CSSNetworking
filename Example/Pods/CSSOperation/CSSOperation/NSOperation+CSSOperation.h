//
//  NSOperation+CSSOperation.h
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - ********************* NSOperationQueue+CSSOperationStart *********************
@interface NSOperation (CSSOperationStart)

/** 立即执行 */
- (void)syncStart;

/**
 异步执行
 - 如果前一个操作在未完成，那么新操作将被加入队列。执行方式由队列的类型决定（operationType）
 */
- (void)asyncStart;

/** 当前操作依赖其它操作 */
- (void)dependencyOperations:(NSOperation *)newOperation, ...;

@end


#pragma mark - ********************* NSOperationQueue+CSSOperationDispatchManager *********************
@interface NSOperationQueue (CSSOperationDispatchManager)

/**
 立即执行Operation
 - 不加入队列，直接执行
 */
+ (void)syncStartOperations:(NSOperation *)newOperation, ...;

/**
 异步执行Operation
 - 队列类型由操作具体指定（CSSOperation的operationType）
 */
+ (void)asyncStartOperations:(NSOperation *)newOperation, ...;

@end

