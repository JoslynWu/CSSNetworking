//
//  CSSNetworkingDefine.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/26.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//
// https://github.com/JoslynWu/CSSNetworking
// 

#ifndef CSSNetworkingDefine_h
#define CSSNetworkingDefine_h

typedef unsigned long CSSRequestID;
typedef void(^outputHandler)(NSDictionary *resp);

typedef NS_ENUM(NSInteger,CSSWebResponseType) {
    SUCCESS,
    FAILURE,
    CACHE
};

typedef NS_ENUM(NSInteger, CSSWebRequestMethod) {
    POST,   // default
    GET,
    PUT,
    PATCH,
    DELETE,
};

/** 序列化方式 */
typedef NS_ENUM(NSInteger, CSSResponseSerializerType) {
    JSON,   // default
    IMAGE,
};

/** 转模型的方式 */
typedef NS_ENUM(NSInteger, CSSProcessStyle) {
    CSSModel,       // https://github.com/JoslynWu/CSSModel, default
    YYModel,        // https://github.com/ibireme/YYModel
    MJExtension,    // https://github.com/CoderMJLee/MJExtension
    Custom,         // 自定义
};

/** 转模型的方式 */
typedef NS_OPTIONS(NSUInteger, CSSNetworkingLogOptions) {
    Request     = 1 << 0,   // 请求log. 支持 CSSNetworkingManager 和 CSSWebRequest
    Response    = 1 << 1,   // 响应log. 支持 CSSNetworkingManager 和 CSSWebRequest
    Exception   = 1 << 2,   // 异常(缓存异常)log. 支持 CSSNetworkingManager
    
    None        = 0 << 16,  // 无log. 支持CSSNetworkingManager 和 CSSWebRequest
    Single      = 1 << 16,  // 单请求log. 支持CSSNetworkingManager
};

#ifdef DEBUG
#define CSSNetworkLog(...) NSLog(__VA_ARGS__)
#else
#define CSSNetworkLog(...)
#endif

#endif /* CSSNetworkingDefine_h */
