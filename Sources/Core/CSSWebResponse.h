//
//  CSSWebResponse.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSNetworkingDefine.h"

@class CSSWebRequestTask;

@interface CSSWebResponseData : NSObject

@end


@interface CSSWebResponse : NSObject

/** 响应的结果类型 */
@property (nonatomic, assign) CSSWebResponseType respType;

/** 响应解析后的对象 */
@property (nonatomic, strong) CSSWebResponseData *processData;

/** 响应的原始数据 */
@property (nonatomic, strong) NSDictionary *originalData;

/** 请求失败时的 error */
@property (nonatomic, strong) NSError *error;

/** 会话task */
@property (nonatomic, strong) CSSWebRequestTask *task;

/** 输入参数（不经过servers） */
@property (nonatomic, strong) NSDictionary *userInput;

@end

