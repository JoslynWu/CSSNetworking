//
//  CSSWebRequestService.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSWebRequestService.h"
#import "CSSWebRequestTask.h"
#import "CSSWebURLCache.h"
#import "CSSWebRequestTaskCollector.h"
#import <CSSModel/CSSModel.h>
#import <CSSPrettyPrinted/CSSPrettyPrinted.h>
#import "CSSNetworkingManager+Private.h"

static NSString * const CSSWebRequestServiceRespType = @"respType";
static NSString * const CSSWebRequestServiceDataOriginalData = @"originalData";
static NSString * const CSSWebRequestServiceDataTask = @"dataTask";
static NSString * const CSSWebRequestServiceUserInput = @"userInput";
static NSString * const CSSWebRequestServiceError = @"error";

static const NSInteger CSSWebRequestServiceAFNFailureNilErrorCode = -11011;
NSString * const CSSWebRequestServiceErrorDomain = @"com.cssnetworking.error";

@interface CSSWebRequestService()

@property (nonatomic, copy)CSSWebRequestTaskCollector* requestCollector;

@end

@implementation CSSWebRequestService

+ (instancetype)shareService {
    static CSSWebRequestService *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CSSWebRequestService new];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _requestCollector = [CSSWebRequestTaskCollector new];
    return self;
}

#pragma mark  -  publice
-(CSSRequestID)requestApiAsynchronous:(CSSWebRequestTask *)task {
    if(!task) return CSSRequestInvalidID;
    
    task.tid = [self.requestCollector insertRequestTask:task];
    return task.tid;
}

- (BOOL)containRequestUID:(CSSRequestID)tid {
    return [self.requestCollector requestTaskForUid:tid] != nil;
}

- (void)cancelAPI:(CSSRequestID)apiUID {
    [self.requestCollector removeRequestTaskWithUid:apiUID];
}

#pragma mark - process data
+(void)parseSuccedData:(NSDictionary *)responseObj task:(CSSWebRequestTask *)task {
    [self forwardSuccessDataWithRespons:responseObj task:task];
    [[CSSWebRequestService shareService] cancelAPI:task.tid];
}

+ (void)forwardSuccessDataWithRespons:(id)responseObj task:(CSSWebRequestTask *)task {
    NSDictionary *returnDics =@{CSSWebRequestServiceRespType: @(SUCCESS),
                                CSSWebRequestServiceDataOriginalData: responseObj ?: @{},
                                CSSWebRequestServiceDataTask: task.dataTask ? : @{},
                                CSSWebRequestServiceUserInput: task.kernel.userInput ?:@{}};
    
    task.kernel.apiBlockOutputHandler(returnDics);
}

+ (void)parseFailedDataWithError:(NSError*)error task:(CSSWebRequestTask *)task {
    BOOL isCanceled = ![[CSSWebRequestService shareService] containRequestUID:task.tid];
    if (isCanceled) {
        return;
    }
    
    if (!error) {
        error = [NSError errorWithDomain:CSSWebRequestServiceErrorDomain
                                    code:CSSWebRequestServiceAFNFailureNilErrorCode
                                userInfo:@{NSLocalizedFailureReasonErrorKey: @"[CSSNetworking] AFN failure with nil error."}];
    }
    
    NSDictionary *returnDics =@{CSSWebRequestServiceRespType: @(FAILURE),
                                CSSWebRequestServiceError: error,
                                CSSWebRequestServiceUserInput: task.kernel.userInput ?: @{}};
    
    task.kernel.apiBlockOutputHandler(returnDics);
    [[CSSWebRequestService shareService] cancelAPI:task.tid];
}

/* it try to load cache, maybe failed. */
+ (void)loadDataFromCacheWithTask:(CSSWebRequestTask *)task {
    NSURLRequest *urlRequest = nil;
    if([task.dataTask isKindOfClass:[NSURLSessionDataTask class]]) {
        urlRequest = ((NSURLSessionDataTask *)task.dataTask).originalRequest;
    }
    
    if (task.webRequest.isNeedCache) {
        // responseObj 第一次加载缓存的时为nil
        id responseObj = [[CSSWebURLCache sharedURLCache] cacheForRequest:urlRequest];
        NSDictionary *returnDics =@{CSSWebRequestServiceRespType: @(CACHE),
                                    CSSWebRequestServiceDataOriginalData: responseObj ?: @{},
                                    CSSWebRequestServiceDataTask: task.dataTask,
                                    CSSWebRequestServiceUserInput: task.kernel.userInput ?: @{}};
        
        task.kernel.apiBlockOutputHandler(returnDics);
    }
}

#pragma mark  -  request callback style
- (CSSWebRequestKernel *)requestBlockOutputWithTask:(CSSWebRequestTask *)task {
    CSSWebRequestKernel *kernel = [CSSWebRequestKernel new];
    kernel.userInput = task.webRequest.parameters;
    __weak typeof(self) weakSelf = self;
    __weak typeof(task) weakTask = task;
    kernel.apiBlockOutputHandler = ^(NSDictionary *responseData){
        CSSWebResponseType respType = ((NSNumber *)[responseData objectForKey:CSSWebRequestServiceRespType]).integerValue;
        CSSWebResponse *resp = [[CSSWebResponse alloc] init];
        resp.originalData = responseData[CSSWebRequestServiceDataOriginalData];
        resp.userInput = responseData[CSSWebRequestServiceUserInput];
        resp.error = responseData[CSSWebRequestServiceError];
        resp.respType = respType;
        resp.task = weakTask;
        resp.processData = [weakSelf _toModelWithResponse:resp];
        if (respType == CACHE) {
            if (weakTask.webRequest.isNeedForwardCache) {
                !weakTask.webRequest.sucessBlock ?: weakTask.webRequest.sucessBlock(resp);
            } else {
                !weakTask.webRequest.fromCacheBlock ?: weakTask.webRequest.fromCacheBlock(resp);
            }
        } else if(respType == SUCCESS) {
            [[CSSNetworkingManager sharedClient] globalSuccessHandleForTask:weakTask];
            !weakTask.webRequest.gloabDataProcess ?: weakTask.webRequest.gloabDataProcess(resp);
            !weakTask.webRequest.sucessBlock ?: weakTask.webRequest.sucessBlock(resp);
            if (weakTask.webRequest.isNeedCache && [[CSSNetworkingManager sharedClient] strictSuccessForResponse:resp]) {
                [weakSelf storeCacheWithResponse:resp];
            }
        } else {
            [[CSSNetworkingManager sharedClient] globalFailureHandleForTask:weakTask];
            !weakTask.webRequest.failedBlock ?: weakTask.webRequest.failedBlock(resp);
        }
        if (respType != CACHE) {
            [self _logWithTask:weakTask responseData:responseData];
        }
    };
    return kernel;
}

#pragma mark  -  private
- (void)storeCacheWithResponse:(CSSWebResponse *)resp {
    NSURLResponse *urlResponese = nil;
    NSURLRequest *urlRequest = nil;
    CSSWebRequestTask *task = resp.task;
    if([task.dataTask isKindOfClass:[NSURLSessionDataTask class]]) {
        urlResponese = ((NSURLSessionDataTask*)task.dataTask).response;
        urlRequest   = ((NSURLSessionDataTask*)task.dataTask).originalRequest;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[CSSWebURLCache sharedURLCache] storeCache:resp.originalData withRespone:urlResponese forRequest:urlRequest];
    });
}


- (CSSWebResponseData *)_toModelWithResponse:(CSSWebResponse *)resp {
    CSSWebRequestTask *task = resp.task;
    if (!task.webRequest.responseDataClass) {
        return nil;
    }
    if (resp.originalData.count <= 0) {
        return nil;
    }
    if ([resp.originalData isKindOfClass:[NSData class]]) {
        return nil;
    }
    
    if (task.webRequest.processStyle == CSSModel) {
        return  [task.webRequest.responseDataClass css_modelWithJson:resp.originalData];
    }
    
    if (task.webRequest.processStyle == YYModel) {
        SEL toModelSEL = NSSelectorFromString(@"yy_modelWithJSON:");
        NSAssert([task.webRequest.responseDataClass respondsToSelector:toModelSEL], @"plase import YYModel");
        return [self jsonToModelWithSelector:toModelSEL response:resp];
    }
    
    if (task.webRequest.processStyle == MJExtension) {
        SEL toModelSEL = NSSelectorFromString(@"mj_objectWithKeyValues:");
        NSAssert([task.webRequest.responseDataClass respondsToSelector:toModelSEL], @"plase import MJExtension");
        return [self jsonToModelWithSelector:toModelSEL response:resp];
    }
    
    if (task.webRequest.processStyle == Custom) {
        return [[CSSNetworkingManager sharedClient] customProcessForResponse:resp];
    }
    
    return nil;
}

- (CSSWebResponseData *)jsonToModelWithSelector:(SEL)selector response:(CSSWebResponse *)resp {
    IMP imp = [NSObject methodForSelector:selector];
    CSSWebResponseData *(*jsonToModelIMP)(id, SEL, id) = (void *)imp;
    Class cls = resp.task.webRequest.responseDataClass;
    return jsonToModelIMP(cls, selector, resp.originalData);
}

- (void)_logWithTask:(CSSWebRequestTask *)task responseData:(NSDictionary *)responseData{
    BOOL flag = NO;
    if (([CSSNetworkingManager sharedClient].logOptions & Response) == Response) {
        flag = YES;
    }
    
    if (([CSSNetworkingManager sharedClient].logOptions & Single) == Single) {
        if ((task.webRequest.logOptions & Response) == Response) {
            flag = YES;
        }
    }
    if (!flag) {
        return;
    }
    
    CSSNetworkLog(@"\n****************** [CSSNetworking] responseData: ****************** \
                 \nclass: %@ \
                 \nid: %zd \
                 \nurl: %@ \
                 \nparameters: %@ \
                 \ndata:\n%@\
                 \n********************************************************************",
                 NSStringFromClass(task.webRequest.responseDataClass),
                 task.tid,
                 task.dataTask.originalRequest.URL.absoluteString,
                 [[NSString alloc] initWithData:task.dataTask.originalRequest.HTTPBody encoding:NSUTF8StringEncoding],
                 responseData.css_debugSting);
}

@end

