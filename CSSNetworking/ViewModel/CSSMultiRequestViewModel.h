//
//  CSSMultiRequestViewModel.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/2/5.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSNetworkingDefine.h"
#import "CSSWebRequest.h"
#import "CSSWebResponse.h"
#import <CSSOperation/CSSOperation.h>

#pragma mark - ********************* CSSMultiRequestInfo *********************
NS_ASSUME_NONNULL_BEGIN
@interface CSSMultiRequestInfo : NSObject

/** 请求标记 */
@property (nonatomic, assign) NSInteger requestId;

/** 请求实例 */
@property (nonatomic ,strong) CSSWebRequest *request;

/** 请求参数（对象形式） */
@property (nonatomic, strong) CSSWebRequestData *requestData;

/** 响应对象 */
@property (nonatomic, strong) CSSWebResponseData *respData;

/** 单个请求是否完成 */
@property (nonatomic, assign, readonly, getter=isRequestComplete) BOOL requestComplete;

/**
 是否为例外。
 - 例外是相对于`sendAllRequest`而言。
 - YES 表示调用`sendAllRequest`时不用触发请求；
 - NO 反之。可以在之后单独发送请求（通过`sendSingleRequestWithId:`）。
 */
@property (nonatomic, assign, getter=isIndependent) BOOL independent;

@end
NS_ASSUME_NONNULL_END


#pragma mark - ********************* CSSMultiRequestViewModelDelegate *********************
NS_ASSUME_NONNULL_BEGIN
@class CSSMultiRequestViewModel;
typedef CSSMultiRequestViewModel vmCls;

@protocol CSSMultiRequestViewModelDelegate <NSObject>

@optional

/**
 请求返回后调用
 - 在 `success`和`failed`之前调用
 */
- (void)viewModel:(vmCls *)vm complete:(CSSWebResponse *)resp requestId:(NSInteger)rid;

/**
 成功时回调
 - 成功条件为严格条件。
 - 严格条件可以通过 `manager:strictSuccessForResponse:` 定制
 */
- (void)viewModel:(vmCls *)vm success:(CSSWebResponse *)resp requestId:(NSInteger)rid;

/**
 失败时调用
 - 严格的失败。 即为严格成功的else
 */
- (void)viewModel:(vmCls *)vm failed:(CSSWebResponse *)resp requestId:(NSInteger)rid;

/**
 加载缓存时回调。
 - request.needCache = NO; 时不调用。
 */
- (void)viewModel:(vmCls *)vm cache:(CSSWebResponse *)resp requestId:(NSInteger)rid;

@end
NS_ASSUME_NONNULL_END


#pragma mark - ********************* CSSMultiRequestViewModel *********************
NS_ASSUME_NONNULL_BEGIN
typedef CSSMultiRequestInfo CSSRequestInfo;
typedef void(^CSSMultiRequestConfigBlcok)(CSSRequestInfo *requestInfo);

@interface CSSMultiRequestViewModel : NSObject

/**
 初始化方法

 @param delegate delegate
 @param block 可以在其中添加请求，和发送请求
 @return instance
 */
- (instancetype)initWithDelegate:(nullable id<CSSMultiRequestViewModelDelegate>)delegate
                      addRequest:(nullable void(^)(vmCls *make))block NS_DESIGNATED_INITIALIZER;

/**
 添加请求

 @param rid 请求的标记ID，可以作为回调时的标记区分
 @param configBlock 配置请求信息
 */
- (void)addRequestWithId:(NSInteger)rid config:(CSSMultiRequestConfigBlcok)configBlock;

/**
 发送全部请求

 @return 操作组。可以指定其优先级等
 */
- (CSSOperation *)sendAllRequest;

/**
 发送指定请求

 @param rid 请求的ID
 @return 操作组。可以指定其优先级等
 */
- (CSSOperation *)sendSingleRequestWithId:(NSInteger)rid;

/** 获取指定请求信息 */
- (CSSRequestInfo *)requestInfoWithId:(NSInteger)rid;

/** 移除指定请求 */
- (void)removeRequestInfoWithId:(NSInteger)rid;

/** 一组请求结束时的回调。单个请求也可视为一组请求 */
@property (nonatomic, copy) void(^endAllRequest)(void);

/**
 当前`CSSMultiRequestViewModel`是否在请求中
 - 只要有一个请求在发送中就会标记为YES
 */
@property (nonatomic, assign, readonly, getter=isRequesting) BOOL requesting;

@end
NS_ASSUME_NONNULL_END


