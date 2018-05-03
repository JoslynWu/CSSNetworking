//
//  BaseOperation.m
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import "CSSOperation.h"
#import <pthread/pthread.h>

CSSOperationType const kCSSOperationTypeSingleton = @"CSSOperationTypeSingleton";
CSSOperationType const kCSSOperationTypeSerial = @"CSSOperationTypeSerial";
CSSOperationType const kCSSOperationTypeConcurrent = @"CSSOperationTypeConcurrent";

static NSOperationQueue *_CSSOperationManagerQueue(CSSOperationType type) {
    static NSMutableDictionary *queues = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        queues = [NSMutableDictionary dictionary];
    });
    
    NSOperationQueue *queue = queues[type];
    if (!queue) {
        queue = [NSOperationQueue new];
        queue.name = type;
        queues[type] = queue;
    }
    
    return queue;
}

@implementation CSSOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - lifecycle
- (instancetype)init {
    return [self initWithOperationType:kCSSOperationTypeConcurrent];
}

- (instancetype)initWithOperationType:(CSSOperationType)type {
    self = [super init];
    if (!self) {
        return nil;
    }
    _operationType = type;
    return self;
}

#pragma mark - Template Sub Methods
+ (NSOperationQueue *)_queueForOperation:(NSOperation *)newOperation {
    
    CSSOperation *tempOperation = (CSSOperation *)newOperation;
    CSSOperationType operationType = tempOperation.operationType ?: kCSSOperationTypeConcurrent;
    NSOperationQueue *queue = _CSSOperationManagerQueue(operationType);
    
    if (operationType == kCSSOperationTypeSingleton) {
        for (NSOperation *operation in [queue operations]) {
            if ([operation isMemberOfClass:self]) {
                queue = nil;
                break;
            }
        }
    } else if (operationType == kCSSOperationTypeSerial) {
        [queue.operations enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isMemberOfClass:self]) {
                [tempOperation addDependency:(NSOperation *)obj];
                *stop = YES;
            }
        }];
    }
    
    return queue;
}

#pragma mark - Pubilc Methods
- (void)start {
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    CSSOperationBlock block = self.blockOnMainThread;
    if (block) {
        if (pthread_main_np()) {
            block(self);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(self);
            });
        }
    } else {
        block = self.blockOnCurrentThread;
        !block ?: block(self);
    }
}

- (void)cancel {
    [super cancel];
    self.finished = YES;
    self.executing = NO;
}

#pragma mark - Set
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

@end

