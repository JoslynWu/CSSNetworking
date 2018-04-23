//
//  CSSNetworkingManager.m
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/26.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSNetworkingManager.h"
#import "CSSWebRequestTask.h"
#import "CSSWebRequestService.h"

static NSArray *methodStrings;
static const NSTimeInterval CSSRequestDefaultTimeoutInterval = 30;

@interface CSSNetworkingManager ()

@end

@implementation CSSNetworkingManager

#pragma mark  -  public
+ (instancetype)sharedClient {
    static CSSNetworkingManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CSSNetworkingManager alloc] init];
        instance.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        instance.requestSerializer = [AFJSONRequestSerializer serializer];
        methodStrings = @[@"POST", @"GET", @"PUT", @"PATCH", @"DELETE"];
        instance.logOptions = Single;
    });
    return instance;
}

+ (BOOL)isNetworkReachable {
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

+ (BOOL)isNetworkViaWifi {
    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi];
}

+ (BOOL)isNetworkViaWWAN {
    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN];
}

#pragma mark  -  private
- (CSSWebResponseData *)customProcessForResponse:(CSSWebResponse *)resp {
    if ([self.delgate respondsToSelector:@selector(manager:customProcessForResponse:)]) {
        return [self.delgate manager:self customProcessForResponse:resp];
    }
    return nil;
}

- (BOOL)strictSuccessForResponse:(CSSWebResponse *)resp {
    if ([self.delgate respondsToSelector:@selector(manager:strictSuccessForResponse:)]) {
        return [self.delgate manager:self strictSuccessForResponse:resp];
    }
    return resp.respType = SUCCESS;
}

- (void)globalSuccessHandleForTask:(CSSWebRequestTask *)task {
    if ([self.delgate respondsToSelector:@selector(manager:globalSuccessHandleForTask:)]) {
        [self.delgate manager:self globalSuccessHandleForTask:task];
    }
}

- (void)globalFailureHandleForTask:(CSSWebRequestTask *)task {
    if ([self.delgate respondsToSelector:@selector(manager:globalFailureHandleForTask:)]) {
        [self.delgate manager:self globalFailureHandleForTask:task];
    }
}

- (void)cancelWithTask:(CSSWebRequestTask *)task {
    [((NSURLSessionDataTask *)task.dataTask) cancel];
}

- (NSString *)methodStringWithMethodType:(CSSWebRequestMethod)type {
    return [methodStrings objectAtIndex:type];
}

- (void)completed:(CSSWebRequestTask *)task {
    [[CSSWebRequestService shareService] cancelAPI:task.tid];
}

static inline NSString *CSSContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

- (void)startFormRequestWithTask:(CSSWebRequestTask *)task {
    [[CSSNetworkingManager sharedClient].requestSerializer setValue:@"multipart/form-data; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [self POST:task.webRequest.urlForRequest parameters:task.webRequest.parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSDictionary *items = task.webRequest.formData;
        for(NSString *key in [items allKeys]) {
            id val = [items objectForKey:key];
            if ([val isKindOfClass:[NSURL class]]) {
                //通过url方式获取文件内容
                [formData appendPartWithFileURL:val name:@"file" fileName:key mimeType:@"" error:nil];
            } else if ([val isKindOfClass:[NSData class]]) {
                NSData * data = [items objectForKey:key];
                [formData appendPartWithFileData:data name:@"file" fileName:key mimeType:@"image/jpeg"];
            } else if ([val isKindOfClass:[CSSWebRequestFormItem class]]) {
                CSSWebRequestFormItem *item = (CSSWebRequestFormItem *)val;
                id data = item.data;
                NSURL *itemURL = nil;
                NSData *itemData = nil;
                if ([data isKindOfClass:[NSString class]]) {
                    itemURL = [NSURL fileURLWithPath:(NSString *)data];
                } else if ([data isKindOfClass:[NSURL class]]) {
                    itemURL = (NSURL *)data;
                } else if ([data isKindOfClass:[NSData class]]) {
                    itemData = (NSData *)data;
                }
                
                if (itemURL) {
                    NSString *fileName = item.fileName ?: [itemURL lastPathComponent];
                    NSString *mimeType = item.mimeType ?: CSSContentTypeForPathExtension([itemURL pathExtension]);
                    [formData appendPartWithFileURL:itemURL name:item.name?:key fileName:fileName mimeType:mimeType error:nil];
                }
                
                if (itemData) {
                    NSString *fileName = item.fileName;
                    NSString *mimeType = item.mimeType;
                    
                    NSParameterAssert(fileName);
                    NSParameterAssert(mimeType);
                    
                    [formData appendPartWithFileData:itemData name:item.name?:key fileName:fileName mimeType:mimeType];
                }
            }
        }
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull secssionDataTask, id  _Nullable responseObject) {
        [CSSWebRequestService parseSuccedData:responseObject task:task];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf completed:task];
    } failure:^(NSURLSessionDataTask * _Nullable secssionDataTask, NSError * _Nonnull error) {
        [CSSWebRequestService parseFailedDataWithError:error task:task];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf completed:task];
    }];
    
    task.dataTask = dataTask;
    [dataTask resume];
}

- (void)startNormalRequestWithTask:(CSSWebRequestTask *)task {
    switch (task.webRequest.responseSerializerType) {
        case JSON:
            [CSSNetworkingManager sharedClient].responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case IMAGE:
            [CSSNetworkingManager sharedClient].responseSerializer = [AFImageResponseSerializer serializer];
            break;
            /*
             case PDF:
             [CSSWebRquestSessionManager sharedClient].responseSerializer = [CustomPDFResponseSerializer serializer];
             break;
             */
        default:
            break;
    }
    
    id parameters = task.webRequest.parameters;
    if (task.webRequest.isNeedEncrypt) {
        if (self.delgate && [self.delgate respondsToSelector:@selector(manager:encryptData:)]) {
            parameters = [self.delgate manager:self encryptData:parameters];
        }
    }
    __weak typeof(self) weakSelf = self;
    NSString *methodString = [self methodStringWithMethodType:task.webRequest.requestMethod];
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:methodString URLString:task.webRequest.urlForRequest parameters:parameters success:^(NSURLSessionDataTask *secssionDataTask, id responseObj){
        if(task.webRequest.isNeedEncrypt) {
            if (weakSelf.delgate && [weakSelf.delgate respondsToSelector:@selector(manager:decryptData:)]) {
                id decodeObject = [weakSelf.delgate manager:weakSelf decryptData:responseObj];
                responseObj = decodeObject ?: responseObj;
            }
        }
        [CSSWebRequestService parseSuccedData:responseObj task:task];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf completed:task];
        
    } failure:^(NSURLSessionDataTask *secssionDataTask, NSError *error) {
        [CSSWebRequestService parseFailedDataWithError:error task:task];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf completed:task];
    }];
    task.dataTask = dataTask;
    if (task.webRequest.isNeedCache) {
        [CSSWebRequestService loadDataFromCacheWithTask:task];
    }
    [dataTask resume];
}

- (void)startRequestWithTask:(CSSWebRequestTask *)task {
    [self assembleHeaderForRequestWithTask:task];
    
    if (task.webRequest.formData) {
        [self startFormRequestWithTask:task];
        return;
    }
    
    [self startNormalRequestWithTask:task];
}


- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure
{
    NSError *serializationError = nil;
    NSString *str = [[NSURL URLWithString:URLString] absoluteString];
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method URLString:str parameters:parameters error:&serializationError];
    if (serializationError) {
        if (failure) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu" a
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
#pragma clang diagnostic pop
        }
        return nil;
    }

    request.timeoutInterval = self.timeoutInterval ?: CSSRequestDefaultTimeoutInterval;
    
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error)
                {
                    if (error) {
                        if (failure) {
                            failure(dataTask, error);
                        }
                    } else {
                        if (success) {
                            success(dataTask, responseObject);
                        }
                    }
                }];
    
    return dataTask;
}

#pragma mark  -  action
- (void)assembleHeaderForRequestWithTask:(CSSWebRequestTask *)task {
    NSMutableDictionary *tempHeaders = [NSMutableDictionary new];
    [tempHeaders setValue:@"application/json; charset=utf8" forKey:@"Content-Type"];
    
    if (self.delgate && [self.delgate respondsToSelector:@selector(manager:globalHeaderForTask:)]) {
        NSDictionary *globalHeaders = [self.delgate manager:self globalHeaderForTask:task];
        if (globalHeaders.count > 0) {
            [tempHeaders addEntriesFromDictionary:globalHeaders];
        }
    }
    
    if(task.webRequest.headers.count) {
        [tempHeaders addEntriesFromDictionary:task.webRequest.headers];
    }
    
    task.webRequest.headers = tempHeaders.copy;
    
    for (NSString *key in [task.webRequest.headers allKeys]) {
        [self.requestSerializer setValue:[task.webRequest.headers objectForKey:key] forHTTPHeaderField:key];
    }
}

@end

