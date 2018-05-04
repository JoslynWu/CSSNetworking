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
@property (nonatomic, assign, readwrite, getter=isRequestComplete) BOOL requestComplete;
@end

@implementation CSSMultiRequestInfo
@end


@interface CSSMultiRequestViewModel ()

@property (nonatomic, weak) id<CSSMultiRequestViewModelDelegate> delegate;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, CSSMultiRequestInfo *> *requestInfo;
@property (nonatomic, assign, readwrite, getter=isRequesting) BOOL requesting;
@property (nonatomic, strong) CSSOperation *currentOperation;
@property (nonatomic, strong) NSDictionary<CSSOperationType, NSOperationQueue *> *operationQueues;

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
    _requesting = NO;
    NSOperationQueue *serialQueue = [[NSOperationQueue alloc] init];
    serialQueue.name = @"CSSMultiRequestViewModelOperationTypeSerialQueue";
    _operationQueues = @{kCSSOperationTypeSerial: serialQueue};
    if (block) {
        block(self);
    }
    return self;
}

- (void)addRequestWithId:(NSInteger)rid config:(CSSMultiRequestConfigBlcok)configBlock {
    CSSMultiRequestInfo *model = [CSSMultiRequestInfo new];
    model.requestId = rid;
    [self.requestInfo setObject:model forKey:@(rid)];
    if (configBlock) {
        configBlock(model);
    }
    [self _buildRequestWithModel:model];
}

- (CSSOperation *)sendAllRequest {
    CSSOperation *operation = [[CSSOperation alloc] initWithOperationType:kCSSOperationTypeSerial];
    operation.queues = self.operationQueues;
    __weak typeof(self) weakSelf = self;
    operation.blockOnCurrentThread = ^(CSSOperation *make) {
        weakSelf.currentOperation = make;
        [weakSelf _sendAllRequest];
    };
    [operation asyncStart];
    return operation;
}

- (CSSOperation *)sendSingleRequestWithId:(NSInteger)rid {
    CSSOperation *operation = [[CSSOperation alloc] initWithOperationType:kCSSOperationTypeSerial];
    operation.queues = self.operationQueues;
    __weak typeof(self) weakSelf = self;
    operation.blockOnCurrentThread = ^(CSSOperation *make) {
        weakSelf.currentOperation = make;
        [weakSelf _sendSingleRequestWithId:rid];
    };
    [operation asyncStart];
    return operation;
}

- (CSSRequestInfo *)requestInfoWithId:(NSInteger)rid {
    return [self.requestInfo objectForKey:@(rid)];
}

- (void)removeRequestInfoWithId:(NSInteger)rid {
    [self.requestInfo removeObjectForKey:@(rid)];
}

#pragma mark  -  private
- (void)_sendAllRequest {
    self.requesting = NO;
    [self _recoverRequestBoolStatusWithFlag:NO];
    for (CSSMultiRequestInfo *model in self.requestInfo.allValues) {
        if (!model.isIndependent) {
            [model.request cancelFetch];
            [model.request sendRequest];
        }
    }
}

- (void)_sendSingleRequestWithId:(NSInteger)rid {
    self.requesting = NO;
    [self _recoverRequestBoolStatusWithFlag:YES];
    CSSMultiRequestInfo *model = [self.requestInfo objectForKey:@(rid)];
    model.requestComplete = NO;
    [model.request cancelFetch];
    [model.request sendRequest];
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
    for (CSSMultiRequestInfo *model in self.requestInfo.allValues) {
        if (!model.isRequestComplete) {
            if (!model.isIndependent) {
                return;
            }
        }
    }
    [self _recoverRequestBoolStatusWithFlag:NO];
    self.requesting = YES;
    [self _executeCompleteHandle];
    self.currentOperation.finished = YES;
    self.currentOperation.executing = NO;
}

- (void)_executeCompleteHandle {
    if (self.endAllRequest) {
        if ([NSThread currentThread].isMainThread) {
            self.endAllRequest();
        } else {
            dispatch_async(dispatch_get_main_queue(), self.endAllRequest);
        }
    }
}

- (void)_recoverRequestBoolStatusWithFlag:(BOOL)flag {
    for (CSSMultiRequestInfo *model in self.requestInfo.allValues) {
        model.requestComplete = flag;
    }
}

- (void)_refreshRequestBoolStatusWith:(NSInteger)rid {
    for (CSSMultiRequestInfo *model in self.requestInfo.allValues) {
        if (model.requestId == rid) {
            model.requestComplete = true;
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


