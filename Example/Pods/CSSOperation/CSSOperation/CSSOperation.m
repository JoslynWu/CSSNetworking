//
//  BaseOperation.m
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import "CSSOperation.h"

CSSOperationType const kCSSOperationTypeSingleton = @"CSSOperationTypeSingleton";
CSSOperationType const kCSSOperationTypeSerial = @"CSSOperationTypeSerial";
CSSOperationType const kCSSOperationTypeConcurrent = @"CSSOperationTypeConcurrent";

static NSOperationQueue *_CSSOperationManagerGlobalQueue(CSSOperationType type) {
    static NSMutableDictionary *globalQueues = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        globalQueues = [NSMutableDictionary dictionary];
    });
    
    NSOperationQueue *queue = globalQueues[type];
    if (!queue) {
        queue = [NSOperationQueue new];
        queue.name = type;
        globalQueues[type] = queue;
    }
    
    return queue;
}

@interface CSSOperation()

@property (nonatomic, strong) NSHashTable<__kindof NSOperation *> *dependencyTable;
@property (nonatomic, copy) dispatch_block_t userCompletionHandle;

@end

@implementation CSSOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize ready = _ready;

#pragma mark - lifecycle
- (instancetype)init {
    return [self initWithOperationType:kCSSOperationTypeConcurrent queue:nil];
}

+ (instancetype)operationWithType:(CSSOperationType)type {
    return [[self alloc] initWithOperationType:type queue:nil];
}

+ (instancetype)operationWithType:(CSSOperationType)type
                            queue:(nullable NSDictionary<CSSOperationType, __kindof NSOperationQueue *> *)queues {
    return [[self alloc] initWithOperationType:type queue:queues];
}

- (instancetype)initWithOperationType:(CSSOperationType)type queue:(nullable NSDictionary<CSSOperationType, __kindof NSOperationQueue *> *)queues {
    self = [super init];
    if (!self) {
        return nil;
    }
    _operationType = type;
    _queues = queues;
    return self;
}

#pragma mark - Template Sub Methods
+ (NSOperationQueue *)_queueForOperation:(__kindof CSSOperation *)newOperation {
    
    CSSOperationType type = newOperation.operationType;
    if (type.length <= 0) {
        return nil;
    }
    
    NSOperationQueue *queue = newOperation.currentQueue;
    if (queue.operations.count <= 0) {
        newOperation.ready = YES;
    }
    
    if (type == kCSSOperationTypeSingleton) {
        for (NSOperation *operation in [queue operations]) {
            if ([operation isMemberOfClass:self]) {
                queue = nil;
                break;
            }
        }
        
    } else if (type == kCSSOperationTypeSerial) {
        [queue.operations enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof NSOperation *op, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([op isMemberOfClass:self]) {
                [newOperation addDependency:op];
                *stop = YES;
            }
        }];
    } else if (type == kCSSOperationTypeConcurrent) {
        if (newOperation.dependencyTable.count <= 0) {
            newOperation.ready = YES;
        }
    }
    
    return queue;
}

#pragma mark - super methods
- (void)start {
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    CSSOperationBlock block = self.blockOnMainThread;
    if (block) {
        if ([NSThread currentThread].isMainThread) {
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
    self.ready = YES;
    self.executing = NO;
    self.finished = YES;
}

- (void)addDependency:(__kindof NSOperation *)op {
    if (![op isKindOfClass:[self class]]) {
        [super addDependency:op];
        return;
    }
    
    @synchronized(self.dependencyTable) {
        self.ready = NO;
        [self.dependencyTable addObject:op];
    }
    dispatch_block_t userCompletionBlcok = op.completionBlock ?: nil;
    ((CSSOperation *)op).userCompletionHandle = userCompletionBlcok;
    __weak typeof(self) weakSelf = self;
    __weak typeof(op) weakOp = op;
    op.completionBlock = ^{
        !userCompletionBlcok ?: userCompletionBlcok();
        [weakSelf removeDependency:weakOp];
    };
}

- (void)removeDependency:(__kindof NSOperation *)op {
    if (![op isKindOfClass:[self class]]) {
        [super removeDependency:op];
        return;
    }
    
    op.completionBlock = ((CSSOperation *)op).userCompletionHandle;
    @synchronized(self.dependencyTable) {
        if ([self.dependencyTable containsObject:op]) {
            [self.dependencyTable removeObject:op];
        }
        if (self.dependencyTable.count <= 0) {
            if (!self.ready) {
                self.ready = YES;
            }
        }
    }
}

#pragma mark - Get
- (NSHashTable<NSOperation *> *)dependencyTable {
    if (!_dependencyTable) {
        _dependencyTable = [NSHashTable weakObjectsHashTable];
    }
    return _dependencyTable;
}

#pragma mark - Set
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _finished = finished;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    _executing = executing;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
}

- (void)setReady:(BOOL)ready {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    _ready = ready;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
}

#pragma mark - ********************* public *********************
- (__kindof NSOperationQueue *)currentQueue {
    CSSOperationType type = self.operationType;
    
    if (self.queues.count && [self.queues.allKeys containsObject:type] &&
        [self.queues[type] isKindOfClass:[NSOperationQueue class]]){
        return self.queues[type];
    }
    
    return _CSSOperationManagerGlobalQueue(type);;
}

@end

