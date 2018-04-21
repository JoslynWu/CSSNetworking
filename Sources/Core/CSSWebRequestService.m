//
//  CSSWebRequestService.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSWebRequestService.h"
#import "CSSWebRequestService.h"
#import "CSSWebRequestTask.h"
#import "CSSWebURLCache.h"
#import "CSSWebRequestTaskCollector.h"
#import <CSSModel/CSSModel.h>
#import "CSSNetworkingManager+Private.h"

static NSString * const CSSWebRequestServiceCode = @"code";
static NSString * const CSSWebRequestServiceData = @"data";
static NSString * const CSSWebRequestServiceDataTask = @"dataTask";
static NSString * const CSSWebRequestServiceUserInput = @"userInput";
static NSString * const CSSWebRequestServiceError = @"error";

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
    NSDictionary *returnDics =@{CSSWebRequestServiceCode: @(SUCCESS),
                                CSSWebRequestServiceData: responseObj?:@{},
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
        error = [NSError errorWithDomain:task.webRequest.urlForRequest code:-101 userInfo:nil];
    }
    
    NSDictionary *returnDics =@{CSSWebRequestServiceCode: @(FAILURE),
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
        id responseObj = [[CSSWebURLCache sharedURLCache] cacheForRequest:urlRequest];
        if (responseObj) {
            NSDictionary *returnDics =@{CSSWebRequestServiceCode: @(CACHE),
                                        CSSWebRequestServiceData: responseObj,
                                        CSSWebRequestServiceDataTask: task.dataTask,
                                        CSSWebRequestServiceUserInput: task.kernel.userInput ?: @{}};
            
            task.kernel.apiBlockOutputHandler(returnDics);
        }
    }
}

#pragma mark  -  request callback style
- (CSSWebRequestKernel *)requestBlockOutputWithTask:(CSSWebRequestTask *)task {
    CSSWebRequestKernel *kernel = [CSSWebRequestKernel new];
    kernel.userInput = task.webRequest.parameters;
    __weak typeof(self) weakSelf = self;
    __weak typeof(task) weakTask = task;
    kernel.apiBlockOutputHandler = ^(NSDictionary *responseData){
        CSSWebResponseType respType = ((NSNumber *)[responseData objectForKey:CSSWebRequestServiceCode]).integerValue;
        CSSWebResponse *resp = [[CSSWebResponse alloc] init];
        resp.originalData = responseData[CSSWebRequestServiceData];
        resp.userInput = responseData[CSSWebRequestServiceUserInput];
        resp.error = responseData[CSSWebRequestServiceError];
        resp.respType = respType;
        resp.task = weakTask;
        resp.processData = [weakSelf _toModelWithResponse:resp];
        if (respType == CACHE) {
            if (weakTask.webRequest.fromCacheBlock) {
                weakTask.webRequest.fromCacheBlock(resp);
            }
        } else if(respType == SUCCESS) {
            [[CSSNetworkingManager sharedClient] globalSuccessHandleForTask:weakTask];
            if(weakTask.webRequest.gloabDataProcess) {
                weakTask.webRequest.gloabDataProcess(resp);
            }
            if(weakTask.webRequest.sucessBlock) {
                weakTask.webRequest.sucessBlock(resp);
            }
            if (weakTask.webRequest.isNeedCache && [[CSSNetworkingManager sharedClient] strictSuccessForResponse:resp]) {
                [weakSelf storeCacheWithResponse:resp];
            }
        } else {
            [[CSSNetworkingManager sharedClient] globalFailureHandleForTask:weakTask];
            if(weakTask.webRequest.failedBlock) {
                weakTask.webRequest.failedBlock(resp);
            }
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
    if ([resp.originalData isKindOfClass:[NSData class]]) {
        return nil;
    }
    
    if (task.webRequest.processStyle == CSSModel) {
        return  [task.webRequest.responseDataClass css_modelWithJson:resp.originalData];
    }
    
    Class responseDataClass = task.webRequest.responseDataClass;
    if (task.webRequest.processStyle == YYModel) {
        NSString *methodString = @"yy_modelWithJSON:";
        NSAssert([responseDataClass respondsToSelector:NSSelectorFromString(methodString)], @"plase import YYModel");
        return [self modelToJsonWithMethod:methodString response:resp];
    }
    
    if (task.webRequest.processStyle == MJExtension) {
        NSString *methodString = @"mj_objectWithKeyValues:";
        NSAssert([responseDataClass respondsToSelector:NSSelectorFromString(methodString)], @"plase import MJExtension");
        return [self modelToJsonWithMethod:methodString response:resp];
    }
    
    if (task.webRequest.processStyle == Custom) {
        return [[CSSNetworkingManager sharedClient] customProcessForResponse:resp];
    }
    
    return nil;
}

- (CSSWebResponseData *)modelToJsonWithMethod:(NSString *)methodString response:(CSSWebResponse *)resp {
    SEL selector = NSSelectorFromString(methodString);
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
    
    NSString *postString = [[NSString alloc] initWithData:task.dataTask.originalRequest.HTTPBody encoding:NSUTF8StringEncoding];
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
                 postString,
                 responseData.css_debugSting);
}

@end

