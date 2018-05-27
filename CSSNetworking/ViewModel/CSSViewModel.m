//
//  CSSViewModel.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/2/5.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSViewModel.h"
#import "CSSNetworkingManager+Private.h"
#import <objc/runtime.h>

#pragma mark - ********************* CSSVMRequestItem *********************
@interface CSSVMRequestItem ()
@property (nonatomic, copy, nullable) CSSVMConditionBlock successConditionBlock;
@property (nonatomic, copy, nullable) CSSVMConditionBlock failureConditionBlock;
// 被这些rid依赖
@property (nonatomic, strong) NSMutableSet<NSNumber *> *dependencyRids;
@end

@implementation CSSVMRequestItem

- (NSMutableSet<NSNumber *> *)dependencyRids {
    if (_dependencyRids) {
        return _dependencyRids;
    }
    return (_dependencyRids = [NSMutableSet set]);
}

@end


#pragma mark - ********************* CSSViewModel *********************
@interface CSSViewModel ()
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSNumber *, CSSVMRequestItem *> *itemInfos;
@property (nonatomic, strong) CSSOperation *currentOperation;
@property (nonatomic, strong) NSDictionary<CSSOperationType, NSOperationQueue *> *operationQueues;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *activeRids;

@end

@implementation CSSViewModel

#pragma mark - ********************* public *********************
#pragma mark - init
- (instancetype)init {
    return [self initWithDelegate:nil addRequest:nil];
}

+ (nullable instancetype)viewModelWithDelegate:(nullable id<CSSViewModelDelegate>)delegate {
    
    return [self viewModelWithDelegate:delegate addRequest:nil];
}

+ (nullable instancetype)viewModelWithDelegate:(nullable id<CSSViewModelDelegate>)delegate
                                    addRequest:(nullable void(^)(CSSViewModel *make))block {
    
    return [[CSSViewModel alloc] initWithDelegate:delegate addRequest:block];
}

- (nullable instancetype)initWithDelegate:(nullable id<CSSViewModelDelegate>)delegate
                      addRequest:(nullable void(^)(CSSViewModel *make))block {
    self = [super init];
    if (!self) {
        return nil;
    }
    _delegate = delegate;
    _itemInfos = [NSMutableDictionary new];
    _activeRids = [[NSMutableArray alloc] init];
    
    NSOperationQueue *managerSerialQueue = [[NSOperationQueue alloc] init];
    managerSerialQueue.name = @"CSS.MultiRequestViewModel.Mannager.SerialQueue";
    NSOperationQueue *requestConcurrentQueue = [[NSOperationQueue alloc] init];
    requestConcurrentQueue.name = @"CSS.MultiRequestViewModel.request.ConcurrrentQueue";
    _operationQueues = @{kCSSOperationTypeSerial: managerSerialQueue,
                         kCSSOperationTypeConcurrent: requestConcurrentQueue};
    
    if (block) {
        block(self);
    }
    return self;
}

#pragma mark - add request
- (void)addRequestWithId:(NSInteger)rid config:(CSSVMConfigBlcok)configBlock {
    CSSVMRequestItem *item = [CSSVMRequestItem new];
    item.requestId = rid;
    [self.itemInfos setObject:item forKey:@(rid)];
    if (configBlock) {
        configBlock(item);
    }
    [self _buildRequestWithModel:item];
}

#pragma mark - dependency
- (void)addDependencyForRid:(NSInteger)rid from:(NSInteger)fromRid
                    success:(nullable CSSVMConditionBlock)condition {
    
    NSAssert1([self.itemInfos.allKeys containsObject:@(rid)],
              @"[CSSViewModel] contains one invalid rid %li", rid);
    
    CSSVMRequestItem *fromInfo = [self requestInfoWithId:fromRid];
    [fromInfo.dependencyRids addObject:@(rid)];
    fromInfo.successConditionBlock = condition;
}

- (void)addDependencyForRid:(NSInteger)rid from:(NSInteger)fromRid
                    failure:(nullable CSSVMConditionBlock)condition {
    
    NSAssert1([self.itemInfos.allKeys containsObject:@(rid)],
              @"[CSSViewModel] contains one invalid rid %li", rid);
    
    CSSVMRequestItem *fromInfo = [self requestInfoWithId:fromRid];
    [fromInfo.dependencyRids addObject:@(rid)];
    fromInfo.failureConditionBlock  = condition;
}

#pragma mark - send request
- (CSSOperation *)sendAllRequest {
    CSSOperation *operation = [CSSOperation operationWithType:kCSSOperationTypeSerial
                                                        queue:self.operationQueues];
    __weak typeof(self) weakSelf = self;
    operation.blockOnCurrentThread = ^(CSSOperation *maker) {
        weakSelf.currentOperation = maker;
        [weakSelf _sendAllRequest];
    };
    [operation asyncStart];
    return operation;
}

- (CSSOperation *)sendRequestWithIds:(NSInteger)rid, ... {
    NSMutableArray *mArr = [[NSMutableArray alloc] init];
    [mArr addObject:@(rid)];
    va_list argList;
    va_start(argList, rid);
    NSInteger eachRid = NSIntegerMax;
    while ((eachRid = va_arg(argList, NSInteger))) {
        [mArr addObject:@(eachRid)];
    }
    va_end(argList);
    
    CSSOperation *operation = [CSSOperation operationWithType:kCSSOperationTypeSerial
                                                        queue:self.operationQueues];
    __weak typeof(self) weakSelf = self;
    operation.blockOnCurrentThread = ^(CSSOperation *maker) {
        weakSelf.currentOperation = maker;
        [weakSelf _sendRequestWithIds:mArr.copy];
    };
    [operation asyncStart];
    return operation;
}

- (CSSOperation *)sendRequestWithIdArray:(NSArray<NSNumber *> *)rids {
    CSSOperation *operation = [CSSOperation operationWithType:kCSSOperationTypeSerial
                                                        queue:self.operationQueues];
    __weak typeof(self) weakSelf = self;
    operation.blockOnCurrentThread = ^(CSSOperation *maker) {
        weakSelf.currentOperation = maker;
        [weakSelf _sendRequestWithIds:rids];
    };
    [operation asyncStart];
    return operation;
}

#pragma mark - request item
- (CSSOperation *)sendSingleRequestWithId:(NSInteger)rid {
    return [self sendRequestWithIds:rid, nil];
}

- (CSSVMRequestItem *)requestInfoWithId:(NSInteger)rid {
    return [self.itemInfos objectForKey:@(rid)];
}

- (void)removeRequestWithId:(NSInteger)rid {
    [self.itemInfos removeObjectForKey:@(rid)];
}

- (NSInteger)count {
    return self.itemInfos.count;
}

#pragma mark - ********************* private *********************
#pragma mark - send
- (void)_sendRequestWithIds:(NSArray<NSNumber *> *)rids {
    [self.activeRids removeAllObjects];
    NSMutableArray *mArr = [[NSMutableArray alloc] init];
    for (NSNumber *rid in rids) {
        if (![self.itemInfos.allKeys containsObject:rid]) {
            CSSNetworkLog(@"[CSSViewModel] contains one invalid rid %li", rid.integerValue);
            continue;
        }
        [self.activeRids addObject:rid];
        CSSOperation *operation = [self _createOperationWithRequestInfo:self.itemInfos[rid]];
        [mArr addObject:operation];
    }
    [self _addDependencyWithActiveRids:self.activeRids];
    CSSOperation *completeOp = [self _addCompleteOperationWithActiveRequests:mArr.copy];
    [mArr addObject:completeOp];
    [NSOperationQueue asyncStartArray:mArr.copy];
}

- (void)_sendAllRequest {
    NSMutableArray *mArr = [NSMutableArray array];
    for (CSSVMRequestItem *item in self.itemInfos.allValues) {
        if (!item.isIndependent) {
            [mArr addObject:@(item.requestId)];
        }
    }
    [self _sendRequestWithIds:mArr.copy];
}

#pragma mark - operation
- (CSSOperation *)_createOperationWithRequestInfo:(CSSVMRequestItem *)item {
    CSSOperation *operation = [CSSOperation operationWithType:kCSSOperationTypeConcurrent
                                                        queue:self.operationQueues];
    item.operation = operation;
    operation.name = [NSString stringWithFormat:@"%ld", item.requestId];
    __weak CSSVMRequestItem *weakRequestInfo = item;
    operation.blockOnMainThread = ^(__kindof CSSOperation *maker) {
        [weakRequestInfo.request cancelFetch];
        [weakRequestInfo.request sendRequest];
    };

    return operation;
}

- (CSSOperation *)_addCompleteOperationWithActiveRequests:(NSArray<CSSOperation *> *)operations {
    CSSOperation *complete = [CSSOperation operationWithType:kCSSOperationTypeConcurrent
                                                       queue:self.operationQueues];
    [complete addDependencyArray:operations];
    complete.blockOnMainThread = ^(__kindof CSSOperation *maker) {
        [self _executeCompleteHandle];
        maker.executing = NO;
        maker.finished = YES;
        self.currentOperation.finished = YES;
        self.currentOperation.executing = NO;
    };
    return complete;
}

#pragma mark - dependency
- (void)_addDependencyWithActiveRids:(NSArray<NSNumber *> *)rids {
    for (NSNumber *rid in rids) {
        CSSVMRequestItem *item = [self requestInfoWithId:rid.integerValue];
        for (NSNumber *dependencyRid in item.dependencyRids) {
            if ([rids containsObject:dependencyRid]) {
                CSSOperation *afterOp = [self requestInfoWithId:dependencyRid.integerValue].operation;
                [afterOp addDependency:item.operation];
            }
        }
    }
}

- (void)_removeDependencyWithRid:(NSInteger)rid
                      activeRids:(NSArray<NSNumber *> *)rids
                            resp:(CSSWebResponse *)resp
                       isSuccess:(BOOL)success {
    
    CSSVMRequestItem *item = [self requestInfoWithId:rid];
    
    CSSVMConditionBlock block = success ? item.successConditionBlock : item.failureConditionBlock;
    BOOL condition = block ? block(resp) : YES;
    if (condition) { return; }
    
    [self cancelWithRid:rid activeRids:rids];
}

- (void)cancelWithRid:(NSInteger)rid activeRids:(NSArray<NSNumber *> *)rids {
    CSSVMRequestItem *item = [self requestInfoWithId:rid];
    if (item.dependencyRids <= 0) {
        return;
    }
    for (NSNumber *r in item.dependencyRids) {
        if ([rids containsObject:r]) {
            CSSVMRequestItem *subInfo = [self requestInfoWithId:r.integerValue];
            [self.activeRids removeObject:r];
            [subInfo.operation cancel];
            [self cancelWithRid:r.integerValue activeRids:rids];
        }
    }
}

#pragma mark - complete
- (void)_executeCompleteHandle {
    if (self.requestComplete) {
        if ([NSThread currentThread].isMainThread) {
            self.requestComplete(self.activeRids.copy);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.requestComplete(self.activeRids.copy);
            });
        }
    }
}

#pragma mark - request process
- (void)_buildRequestWithModel:(CSSVMRequestItem *)model {
    CSSWebRequest *request = model.request;
    __weak __typeof(self) weakSelf = self;
    request.fromCacheBlock = ^(CSSWebResponse *resp) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf _processResp:resp requestId:model.requestId];
    };
    request.sucessBlock = ^(CSSWebResponse *resp){
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf _processResp:resp requestId:model.requestId];
    };
    request.failedBlock = ^(CSSWebResponse *resp){
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf _processResp:resp requestId:model.requestId];
    };
    request.requestData = model.requestData;
}


- (void)_processResp:(CSSWebResponse *)resp requestId:(NSInteger)rid{
    
    BOOL success = [[CSSNetworkingManager sharedClient] strictSuccessForResponse:resp];
    CSSOperation *operation = self.itemInfos[@(rid)].operation;
    
    if (resp.respType != CACHE) {
        [self _removeDependencyWithRid:rid activeRids:self.activeRids.copy resp:resp isSuccess:success];
    }
    
    if (operation.cancelled) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(viewModel:complete:requestId:)]) {
        [self.delegate viewModel:self complete:resp requestId:rid];
    }
    
    if (resp.respType == CACHE) {
        if ([self.delegate respondsToSelector:@selector(viewModel:cache:requestId:)]) {
            [self.delegate viewModel:self cache:resp requestId:rid];
        }
        return;
    }
    
    if (success) {
        if ([self.delegate respondsToSelector:@selector(viewModel:success:requestId:)]) {
            [self.delegate viewModel:self success:resp requestId:rid];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(viewModel:failure:requestId:)]) {
            [self.delegate viewModel:self failure:resp requestId:rid];
        }
    }
    
    operation.executing = NO;
    operation.finished = YES;
}

@end


