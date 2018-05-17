//
//  CSSMultiRequestViewModel.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/2/5.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSMultiRequestViewModel.h"
#import "CSSNetworkingManager+Private.h"

@interface CSSMultiRequestInfo ()
@property (nonatomic, assign, readwrite, getter=isRequestCompleteFlag) BOOL requestCompleteFlag;
@end

@implementation CSSMultiRequestInfo
@end


@interface CSSMultiRequestViewModel ()

@property (nonatomic, weak) id<CSSMultiRequestViewModelDelegate> delegate;
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

#pragma mark  -  public
- (instancetype)initWithDelegate:(id<CSSMultiRequestViewModelDelegate>)delegate addRequest:(void(^)(vmCls *make))block {
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
    _operationQueues = @{kCSSOperationTypeSerial: managerSerialQueue, kCSSOperationTypeConcurrent: requestConcurrentQueue};
    
    if (block) {
        block(self);
    }
    return self;
}

- (void)addRequestWithId:(NSInteger)rid config:(CSSMultiRequestConfigBlcok)configBlock {
    CSSMultiRequestInfo *requestInfo = [CSSMultiRequestInfo new];
    requestInfo.requestId = rid;
    [self.requestInfo setObject:requestInfo forKey:@(rid)];
    if (configBlock) {
        configBlock(requestInfo);
    }
    [self _buildRequestWithModel:requestInfo];
}

- (CSSOperation *)sendAllRequest {
    CSSOperation *operation = [[CSSOperation alloc] initWithOperationType:kCSSOperationTypeSerial];
    operation.queues = self.operationQueues;
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
    
    CSSOperation *operation = [[CSSOperation alloc] initWithOperationType:kCSSOperationTypeSerial];
    operation.queues = self.operationQueues;
    __weak typeof(self) weakSelf = self;
    operation.blockOnCurrentThread = ^(CSSOperation *maker) {
        weakSelf.currentOperation = maker;
        [weakSelf _sendRequestWithIds:mArr.copy];
    };
    [operation asyncStart];
    return operation;
}

- (CSSOperation *)sendRequestWithIdArray:(NSArray<NSNumber *> *)rids {
    CSSOperation *operation = [[CSSOperation alloc] initWithOperationType:kCSSOperationTypeSerial];
    operation.queues = self.operationQueues;
    __weak typeof(self) weakSelf = self;
    operation.blockOnCurrentThread = ^(CSSOperation *maker) {
        weakSelf.currentOperation = maker;
        [weakSelf _sendRequestWithIds:rids];
    };
    [operation asyncStart];
    return operation;
}

- (CSSOperation *)sendSingleRequestWithId:(NSInteger)rid {
    return [self sendRequestWithIds:rid, nil];
}

- (CSSRequestInfo *)requestInfoWithId:(NSInteger)rid {
    return [self.requestInfo objectForKey:@(rid)];
}

- (void)removeRequestInfoWithId:(NSInteger)rid {
    [self.requestInfo removeObjectForKey:@(rid)];
}

#pragma mark  -  private
- (void)_sendRequestWithIds:(NSArray<NSNumber *> *)rids {
    [self.activeRids removeAllObjects];
    NSMutableArray *mArr = [[NSMutableArray alloc] init];
    for (NSNumber *rid in rids) {
        if (![self.requestInfo.allKeys containsObject:rid]) {
            CSSNetworkLog(@"[CSSMultiRequestViewModel] contains one invalid rid %li", rid.integerValue);
            continue;
        }
        [self.activeRids addObject:rid];
        CSSMultiRequestInfo *model = [self.requestInfo objectForKey:rid];
        model.requestCompleteFlag = NO;
        CSSOperation *operation = [self createOperationWithRequestInfo:self.requestInfo[rid]];
        [mArr addObject:operation];
        [operation asyncStart];
    }
    [self addCompleteOperationWithActiveRequests:mArr.copy];
}

- (CSSOperation *)createOperationWithRequestInfo:(CSSMultiRequestInfo *)requestInfo {
    CSSOperation *operation = [CSSOperation new];
    operation.queues = self.operationQueues;
    requestInfo.operation = operation;
    __weak CSSMultiRequestInfo *weakRequestInfo = requestInfo;
    operation.blockOnMainThread = ^(__kindof CSSOperation *maker) {
        [weakRequestInfo.request cancelFetch];
        [weakRequestInfo.request sendRequest];
    };
    return operation;
}

- (void)_sendAllRequest {
    [self.activeRids removeAllObjects];
    NSMutableArray *mArr = [[NSMutableArray alloc] init];
    for (CSSMultiRequestInfo *info in self.requestInfo.allValues) {
        if (!info.isIndependent) {
            [self.activeRids addObject:@(info.requestId)];
            CSSOperation *operation = [self createOperationWithRequestInfo:info];
            [mArr addObject:operation];
            [operation asyncStart];
        }
    }
    [self addCompleteOperationWithActiveRequests:mArr.copy];
}

- (void)addCompleteOperationWithActiveRequests:(NSArray<CSSOperation *> *)operations {
    CSSOperation *completeOperation = [CSSOperation new];
    completeOperation.queues = self.operationQueues;
    [completeOperation dependencyOperationArray:operations];
    completeOperation.blockOnMainThread = ^(__kindof CSSOperation *maker) {
        [self _executeCompleteHandle];
        maker.executing = NO;
        maker.finished = YES;
        self.currentOperation.finished = YES;
        self.currentOperation.executing = NO;
    };
    [completeOperation asyncStart];
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
    
    if ([[CSSNetworkingManager sharedClient] strictSuccessForResponse:resp]) {
        if ([self.delegate respondsToSelector:@selector(viewModel:success:requestId:)]) {
            [self.delegate viewModel:self success:resp requestId:rid];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(viewModel:failed:requestId:)]) {
            [self.delegate viewModel:self failed:resp requestId:rid];
        }
    }
    CSSOperation *operation = self.requestInfo[@(rid)].operation;
    operation.executing = NO;
    operation.finished = YES;
}

@end


