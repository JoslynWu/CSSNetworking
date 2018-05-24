//
//  NSOperation+CSSOperation.m
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import "NSOperation+CSSOperation.h"

static dispatch_queue_t _CSSOperationDispatchManagerSerialQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.CSSOpationManager.NSOperationManagerSerialQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

#pragma mark - ********************* NSOperationQueue+_CSSOperationManagerTemplate *********************
@interface NSOperation (_CSSOperationManagerTemplate)

+ (void)_asyncStartOperation:(__kindof NSOperation *)newOperation;

@end

@implementation NSOperation (_CSSOperationManagerTemplate)

#pragma mark - Template Method
+ (void)_asyncStartOperation:(__kindof NSOperation *)newOperation {
    // 检测newOperation是否已被处理
    if (![self _operationDidHandle:newOperation]) {
        NSOperationQueue *queue = [self _queueForOperation:newOperation];
        queue ? [queue addOperation:newOperation] : [newOperation cancel];
    }
}

+ (BOOL)_operationDidHandle:(__kindof NSOperation *)newOperation {
    return NO;
}

+ (__kindof NSOperationQueue *)_queueForOperation:(__kindof NSOperation *)newOperation {
    return nil;
}

@end


#pragma mark - ********************* NSOperationQueue+CSSOperationStart *********************
@implementation NSOperation (CSSOperationStart)

- (void)syncStart {
    [NSOperationQueue syncStartOperations:self, nil];
}

- (void)asyncStart {
    [NSOperationQueue asyncStartOperations:self, nil];
}

- (void)addDependencyOperations:(__kindof NSOperation *)newOperation, ... {
    NSMutableArray *operations = [NSMutableArray array];
    [operations addObject:newOperation];
    
    va_list argumentList;
    va_start(argumentList, newOperation);
    
    NSOperation *eachOperation = nil;
    
    while((eachOperation = va_arg(argumentList, NSOperation *))) {
        [operations addObject:eachOperation];
    }
    
    va_end(argumentList);
    
    for (NSOperation *operation in operations) {
        [self addDependency:operation];
    }
}

- (void)addDependencyArray:(NSArray<__kindof NSOperation *> *)operations {
    [operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addDependencyOperations:operation, nil];
    }];
}

@end


#pragma mark - ********************* NSOperationQueue+CSSOperationDispatchManager *********************
@implementation NSOperationQueue (CSSOperationDispatchManager)

#pragma mark -Sync
+ (void)syncStartOperations:(__kindof NSOperation *)newOperation, ... {
    if (newOperation) {
        [newOperation start];
        
        va_list argumentList;
        va_start(argumentList, newOperation);
        
        NSOperation *eachOperation = nil;
        
        while((eachOperation = va_arg(argumentList, NSOperation *))) {
            [eachOperation start];
        }
        
        va_end(argumentList);
    }
}

+ (void)syncStartOperationArray:(NSArray<__kindof NSOperation *> *)operations {
    [operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
        [operation syncStart];
    }];
}

#pragma mark - Async
+ (void)asyncStartOperations:(__kindof NSOperation *)newOperation, ... {
    if (newOperation) {
        NSMutableArray *operations = [NSMutableArray array];
        [operations addObject:newOperation];
        
        va_list argumentList;
        va_start(argumentList, newOperation);
        
        NSOperation *eachOperation = nil;
        
        while((eachOperation = va_arg(argumentList, NSOperation *))) {
            [operations addObject:eachOperation];
        }
        
        va_end(argumentList);
        
        dispatch_async(_CSSOperationDispatchManagerSerialQueue(), ^{
            for (NSOperation *operation in operations) {
                [operation.class _asyncStartOperation:operation];
            }
        });
    }
}

+ (void)asyncStartOperationArray:(NSArray<__kindof NSOperation *> *)operations {
    [operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull operation, NSUInteger idx, BOOL * _Nonnull stop) {
        [operation asyncStart];
    }];
}

@end

