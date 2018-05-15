//
//  CSSMultiRequestViewModel.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/2/5.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSMultiRequestViewModel.h"
#import "CSSNetworkingManager+Private.h"
#import <CSSOperation/NSOperation+CSSOperation.h>

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
    NSOperationQueue *serialQueue = [[NSOperationQueue alloc] init];
    serialQueue.name = @"CSSMultiRequestViewModelOperationTypeSerialQueue";
    _operationQueues = @{kCSSOperationTypeSerial: serialQueue};
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
        NSLog(@"---->%@", @"_sendAllRequest");
        weakSelf.currentOperation = maker;
        [weakSelf _sendAllRequest];
    };
    [operation asyncStart];
    operation.completionBlock = ^{
        NSLog(@"---->%@", [NSThread currentThread]);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"---->%@,%@", @"serialQueue main queue", [NSThread currentThread]);
        }];
    };
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
- (void)_sendAllRequest {
    [self.activeRids removeAllObjects];
    [self _recoverRequestBoolStatusWithFlag:NO];
    for (CSSMultiRequestInfo *model in self.requestInfo.allValues) {
        if (!model.isIndependent) {
            [self.activeRids addObject:@(model.requestId)];
            [model.request cancelFetch];
            [model.request sendRequest];
        }
    }
}

- (void)_sendRequestWithIds:(NSArray<NSNumber *> *)rids {
    [self.activeRids removeAllObjects];
    [self _recoverRequestBoolStatusWithFlag:YES];

    for (NSNumber *rid in rids) {
        if (![self.requestInfo.allKeys containsObject:rid]) {
            CSSNetworkLog(@"[CSSNetworking] contains one invalid rid %li", rid.integerValue);
            continue;
        }
        [self.activeRids addObject:rid];
        CSSMultiRequestInfo *model = [self.requestInfo objectForKey:rid];
        model.requestCompleteFlag = NO;
        [model.request cancelFetch];
        [model.request sendRequest];
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

- (void)_endSingleRefresh{
    NSLog(@"--->%s",__func__);
    for (CSSMultiRequestInfo *model in self.requestInfo.allValues) {
        if (!model.isRequestCompleteFlag) {
            if (!model.isIndependent) {
                return;
            }
        }
    }
    [self _recoverRequestBoolStatusWithFlag:NO];
    [self _executeCompleteHandle];
    self.currentOperation.finished = YES;
    self.currentOperation.executing = NO;
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

- (void)_recoverRequestBoolStatusWithFlag:(BOOL)flag {
    for (CSSMultiRequestInfo *model in self.requestInfo.allValues) {
        model.requestCompleteFlag = flag;
    }
}

- (void)_refreshRequestBoolStatusWith:(NSInteger)rid {
    for (CSSMultiRequestInfo *model in self.requestInfo.allValues) {
        if (model.requestId == rid) {
            model.requestCompleteFlag = true;
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
    
    [self _refreshRequestBoolStatusWith:rid];
    [self _endSingleRefresh];
}

@end


