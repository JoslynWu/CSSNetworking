//
//  CSSMultiRequestViewModel.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/2/5.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSMultiRequestViewModel.h"
#import "CSSNetworkingManager+Private.h"
#import <objc/runtime.h>

#pragma mark - ********************* CSSMultiRequestInfo *********************
@interface CSSMultiRequestInfo ()
@property (nonatomic, copy, nullable) CSSVMConditionBlock successConditionBlock;
@property (nonatomic, copy, nullable) CSSVMConditionBlock failureConditionBlock;
// 被这些rid依赖
@property (nonatomic, strong) NSMutableSet<NSNumber *> *dependencyRids;
@end

@implementation CSSMultiRequestInfo

- (NSMutableSet<NSNumber *> *)dependencyRids {
    if (_dependencyRids) {
        return _dependencyRids;
    }
    return (_dependencyRids = [NSMutableSet set]);
}

@end


#pragma mark - ********************* CSSMultiRequestViewModel *********************
@interface CSSMultiRequestViewModel ()

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, CSSMultiRequestInfo *> *requestInfo;
@property (nonatomic, strong) CSSOperation *currentOperation;
@property (nonatomic, strong) NSDictionary<CSSOperationType, NSOperationQueue *> *operationQueues;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *activeRids;

@end

@implementation CSSMultiRequestViewModel

#pragma mark  -  lifecycle
- (instancetype)init {
    return [self initWithDelegate:nil addRequest:nil];
}

#pragma mark - ********************* public *********************
- (instancetype)initWithDelegate:(id<CSSMultiRequestViewModelDelegate>)delegate
                      addRequest:(void(^)(vmCls *make))block {
    self = [super init];
    if (!self) {
        return nil;
    }
    _delegate = delegate;
    _requestInfo = [NSMutableDictionary new];
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

- (void)addRequestWithId:(NSInteger)rid config:(CSSVMConfigBlcok)configBlock {
    CSSMultiRequestInfo *requestInfo = [CSSMultiRequestInfo new];
    requestInfo.requestId = rid;
    [self.requestInfo setObject:requestInfo forKey:@(rid)];
    if (configBlock) {
        configBlock(requestInfo);
    }
    [self _buildRequestWithModel:requestInfo];
}

- (void)addDependencyForRid:(NSInteger)rid from:(NSInteger)fromRid
                    success:(nullable CSSVMConditionBlock)condition {
    NSAssert1([self.requestInfo.allKeys containsObject:@(rid)],
              @"[CSSMultiRequestViewModel] contains one invalid rid %li", rid);
    
    CSSRequestInfo *fromInfo = [self requestInfoWithId:fromRid];
    [fromInfo.dependencyRids addObject:@(rid)];
    fromInfo.successConditionBlock = condition;
}

- (void)addDependencyForRid:(NSInteger)rid from:(NSInteger)fromRid
                    failure:(nullable CSSVMConditionBlock)condition {
    NSAssert1([self.requestInfo.allKeys containsObject:@(rid)],
              @"[CSSMultiRequestViewModel] contains one invalid rid %li", rid);
    CSSRequestInfo *fromInfo = [self requestInfoWithId:fromRid];
    [fromInfo.dependencyRids addObject:@(rid)];
    fromInfo.failureConditionBlock  = condition;
}

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

#pragma mark - request info
- (CSSOperation *)sendSingleRequestWithId:(NSInteger)rid {
    return [self sendRequestWithIds:rid, nil];
}

- (CSSRequestInfo *)requestInfoWithId:(NSInteger)rid {
    return [self.requestInfo objectForKey:@(rid)];
}

- (void)removeRequestWithId:(NSInteger)rid {
    [self.requestInfo removeObjectForKey:@(rid)];
}

- (NSArray<CSSRequestInfo *> *)allRequestInfo {
    return self.requestInfo.allValues;
}

- (NSInteger)count {
    return self.requestInfo.count;
}

#pragma mark - ********************* private *********************
- (void)_sendRequestWithIds:(NSArray<NSNumber *> *)rids {
    [self.activeRids removeAllObjects];
    NSMutableArray *mArr = [[NSMutableArray alloc] init];
    for (NSNumber *rid in rids) {
        if (![self.requestInfo.allKeys containsObject:rid]) {
            CSSNetworkLog(@"[CSSMultiRequestViewModel] contains one invalid rid %li", rid.integerValue);
            continue;
        }
        [self.activeRids addObject:rid];
        CSSOperation *operation = [self _createOperationWithRequestInfo:self.requestInfo[rid]];
        [mArr addObject:operation];
    }
    [self _addDependencyWithActiveRids:self.activeRids];
    CSSOperation *completeOp = [self _addCompleteOperationWithActiveRequests:mArr.copy];
    [mArr addObject:completeOp];
    [NSOperationQueue asyncStartArray:mArr.copy];
}

- (CSSOperation *)_createOperationWithRequestInfo:(CSSMultiRequestInfo *)requestInfo {
    CSSOperation *operation = [CSSOperation operationWithType:kCSSOperationTypeConcurrent
                                                        queue:self.operationQueues];
    requestInfo.operation = operation;
    operation.name = [NSString stringWithFormat:@"%ld", requestInfo.requestId];
    __weak CSSMultiRequestInfo *weakRequestInfo = requestInfo;
    operation.blockOnMainThread = ^(__kindof CSSOperation *maker) {
        [weakRequestInfo.request cancelFetch];
        [weakRequestInfo.request sendRequest];
    };

    return operation;
}

- (void)_addDependencyWithActiveRids:(NSArray<NSNumber *> *)rids {
    for (NSNumber *rid in rids) {
        CSSRequestInfo *info = [self requestInfoWithId:rid.integerValue];
        for (NSNumber *dependencyRid in info.dependencyRids) {
            if ([rids containsObject:dependencyRid]) {
                CSSOperation *afterOp = [self requestInfoWithId:dependencyRid.integerValue].operation;
                [afterOp addDependency:info.operation];
            }
        }
    }
}

- (void)_removeDependencyWithRid:(NSInteger)rid
                      activeRids:(NSArray<NSNumber *> *)rids
                            resp:(CSSWebResponse *)resp
                       isSuccess:(BOOL)success {
    CSSRequestInfo *info = [self requestInfoWithId:rid];
    CSSVMConditionBlock block = success ? info.successConditionBlock : info.failureConditionBlock;
    BOOL condition = block ? block(resp) : YES;

    for (NSNumber *r in info.dependencyRids.copy) {
        if ([rids containsObject:r]) {
            if (condition) {
                continue;
            }
            [self.activeRids removeObject:r];
            CSSRequestInfo *afterInfo = [self requestInfoWithId:r.integerValue];
            [afterInfo.operation cancel];
            for (NSNumber *subRid in rids) {
                CSSRequestInfo *subInfo = [self requestInfoWithId:subRid.integerValue];
                if ([subInfo.operation.dependencies containsObject:afterInfo.operation]) {
                    [self.activeRids removeObject:subRid];
                    [subInfo.operation cancel];
                }
            }
        }
    }
}

- (void)_sendAllRequest {
    NSMutableArray *mArr = [NSMutableArray array];
    for (CSSMultiRequestInfo *info in self.requestInfo.allValues) {
        if (!info.isIndependent) {
            [mArr addObject:@(info.requestId)];
        }
    }
    [self _sendRequestWithIds:mArr.copy];
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

- (void)_buildRequestWithModel:(CSSMultiRequestInfo *)model {
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
    if ([self.delegate respondsToSelector:@selector(viewModel:complete:requestId:)]) {
        [self.delegate viewModel:self complete:resp requestId:rid];
    }
    
    if (resp.respType == CACHE) {
        if ([self.delegate respondsToSelector:@selector(viewModel:cache:requestId:)]) {
            [self.delegate viewModel:self cache:resp requestId:rid];
        }
        return;
    }
    
    BOOL success = [[CSSNetworkingManager sharedClient] strictSuccessForResponse:resp];
    [self _removeDependencyWithRid:rid activeRids:self.activeRids resp:resp isSuccess:success];
    
    if (success) {
        if ([self.delegate respondsToSelector:@selector(viewModel:success:requestId:)]) {
            [self.delegate viewModel:self success:resp requestId:rid];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(viewModel:failure:requestId:)]) {
            [self.delegate viewModel:self failure:resp requestId:rid];
        }
    }
    CSSOperation *operation = self.requestInfo[@(rid)].operation;
    operation.executing = NO;
    operation.finished = YES;
}

@end


