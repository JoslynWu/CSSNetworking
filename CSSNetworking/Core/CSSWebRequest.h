//
//  CSSWebRequest.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSWebRequestTask.h"
#import "CSSWebResponse.h"
#import "CSSWebRequestFormItem.h"
#import "CSSNetworkingManager.h"

@interface CSSWebRequestData : NSObject
@end


@interface CSSWebRequest : NSObject

#pragma mark - ********************* 构建请求 *********************
/**
 成功时的回调。
 - 一般用于单个请求的全局处理。
 - e.g. 直接在青丘里做用户信息处理。
 */
@property (nonatomic, copy) void(^gloabDataProcess)(CSSWebResponse *resp);

/** 成功时的回 */
@property (nonatomic, copy) void(^sucessBlock)(CSSWebResponse *resp);

/** 失败时的回调 */
@property (nonatomic, copy) void(^failedBlock)(CSSWebResponse *resp);

/**
 通过缓存加载的回调
 - `needCache` 需要为YES
 - 第一次缓存时不会执行
 */
@property (nonatomic, copy) void(^fromCacheBlock)(CSSWebResponse *resp);

/** 请求方式 */
@property (nonatomic, assign) CSSWebRequestMethod requestMethod;

/**
 请求参数
 - 优先级高于 parameters
 - 发送请求时会解析为 NSDictionary 并赋值给 parameters
 */
@property (nonatomic, strong) CSSWebRequestData *requestData;

/** 响应的类。用于数据解析（JSON -> Model）*/
@property (nonatomic, assign) Class responseDataClass;

/**
 数据解析方式
 - 默认为 CSSModel
 - YYModel / MJExtension 需要手动导入对应的库
 - Custom 需要处理 CSSNetworingHandleDelegate 中的 `manager:customProcessForResponse:`
 */
@property (nonatomic, assign) CSSProcessStyle processStyle;

/** 响应的序列化方式， 默认为JSON */
@property (nonatomic, assign) CSSResponseSerializerType responseSerializerType;

/** 请求地址 */
@property (nonatomic, strong) NSString *urlForRequest;;

/** 请求头 */
@property (nonatomic, strong) NSDictionary *headers;

/** 请求参数。优先级低于 `requestData` */
@property (nonatomic, strong) NSDictionary *parameters;

/** 签名。默认为@"" */
@property (nonatomic, strong) NSString *sign;

/** 标记request */
@property (nonatomic, assign, readonly) NSInteger requestId;

/** 是否需要缓存请求 */
@property (nonatomic, assign, getter=isNeedCache) BOOL needCache;

/**
 是否需要加密数据
 - 可以功能通过 `CSSNetworingHandleDelegate` 的方式实现
   加密：`manager:encryptData:`
   解密：`manager:decryptData:`
 */
@property (nonatomic, assign, getter=isNeedEncrypt) BOOL needEncrypt;

/**
 提交的表单数据。
 - CSSWebRequestFormItem设置请看头文件`CSSWebRequestFormItem`
 - 如果不设置 name，则key 作为 multipartFormData 的name.
 */
@property (nonatomic, strong) NSDictionary *formData;

/**
 Log类型。
 - 当`CSSNetworkingManager.logOptions = Single`时有效
 - 默认 None
 */
@property (nonatomic, assign) CSSNetworkingLogOptions logOptions;


/** 将缓存的回调转发给成功的回调。默认 NO. （ respType 会标记为 CACHE ）*/
@property (nonatomic, assign, getter=isisNeedForwardCache) BOOL needForwardCache;


#pragma mark - ********************* 发送或取消请求 *********************
/** 取消请求 */
- (void)cancelFetch;

/** 发送请求 */
- (void)sendRequest;

@end

