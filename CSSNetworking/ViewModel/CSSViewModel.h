//
//  CSSViewModel.h
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

#pragma mark - ********************* CSSVMRequestItem *********************
NS_ASSUME_NONNULL_BEGIN
@interface CSSVMRequestItem : NSObject

/** 请求标记. 不能等于NSIntegerMax */
@property (nonatomic, assign) NSInteger requestId;

/** 请求实例 */
@property (nonatomic ,strong) CSSWebRequest *request;

/** 请求参数（对象形式） */
@property (nonatomic, strong) CSSWebRequestData *requestData;

/** 响应对象 */
@property (nonatomic, strong) CSSWebResponseData *respData;

/**
 是否为例外。
 - 例外是相对于`sendAllRequest`而言。
 - YES 表示调用`sendAllRequest`时不用触发请求；
 - NO 反之。可以在之后单独发送请求（通过`sendSingleRequestWithId:`或者`sendRequestWithIds:`）。
 */
@property (nonatomic, assign, getter=isIndependent) BOOL independent;

/** 请求操作. 每次发送请求时，实例会被重新赋值 */
@property (nonatomic, strong, readonly) CSSOperation *operation;

/** 被该列表的 rid 所依赖 */
@property (nonatomic, strong, readonly) NSMutableSet<NSNumber *> *dependencyRids;

@end
NS_ASSUME_NONNULL_END


#pragma mark - ********************* CSSViewModelDelegate *********************
NS_ASSUME_NONNULL_BEGIN
@class CSSViewModel;

@protocol CSSViewModelDelegate <NSObject>

@optional

/**
 请求返回后调用
 - 在 `success`和`failed`之前调用
 */
- (void)viewModel:(CSSViewModel *)vm complete:(CSSWebResponse *)resp requestId:(NSInteger)rid;

/**
 成功时回调
 - 成功条件为严格条件。
 - 严格条件可以通过 `manager:strictSuccessForResponse:` 定制
 */
- (void)viewModel:(CSSViewModel *)vm success:(CSSWebResponse *)resp requestId:(NSInteger)rid;

/**
 失败时调用
 - 严格的失败。 即为严格成功的else
 */
- (void)viewModel:(CSSViewModel *)vm failure:(CSSWebResponse *)resp requestId:(NSInteger)rid;

/**
 加载缓存时回调。
 - request.needCache = NO; 时不调用。
 */
- (void)viewModel:(CSSViewModel *)vm cache:(CSSWebResponse *)resp requestId:(NSInteger)rid;

@end
NS_ASSUME_NONNULL_END


#pragma mark - ********************* CSSViewModel *********************
NS_ASSUME_NONNULL_BEGIN

typedef void(^CSSVMConfigBlcok)(CSSVMRequestItem *item);
typedef BOOL(^CSSVMConditionBlock)(CSSWebResponse *);

@interface CSSViewModel : NSObject

#pragma mark - init
/**
 初始化方法

 @param delegate delegate
 @param block 可以在其中添加请求，和发送请求
 @return instance
 */
- (nullable instancetype)initWithDelegate:(nullable id<CSSViewModelDelegate>)delegate
                               addRequest:(nullable void(^)(CSSViewModel *make))block NS_DESIGNATED_INITIALIZER;

+ (nullable instancetype)viewModelWithDelegate:(nullable id<CSSViewModelDelegate>)delegate
                                    addRequest:(nullable void(^)(CSSViewModel *make))block;
+ (nullable instancetype)viewModelWithDelegate:(nullable id<CSSViewModelDelegate>)delegate;

@property (nonatomic, weak) id<CSSViewModelDelegate> delegate;

#pragma mark - add request
/**
 添加请求

 @param rid 请求的标记ID，可以作为回调时的标记区分
 @param configBlock 配置请求信息
 */
- (void)addRequestWithId:(NSInteger)rid config:(CSSVMConfigBlcok)configBlock;

#pragma mark - add dependency
/**
 添加成功回调时的条件依赖
 - condition为YES时按照常规方式执行
 - condition为NO时后面的依赖的操作被取消

 @param rid 依赖id
 @param oRid 被依赖的id
 @param condition 条件
 */
- (void)addRid:(NSInteger)rid dependency:(NSInteger)oRid success:(nullable CSSVMConditionBlock)condition;

/**
 添加失败回调时的条件依赖
 - condition为YES时按照常规方式执行
 - condition为NO时后面的依赖的操作被取消
 
 @param rid 依赖id
 @param oRid 被依赖的id
 @param condition 条件
 */
- (void)addRid:(NSInteger)rid dependency:(NSInteger)oRid failure:(nullable CSSVMConditionBlock)condition;

/**
 移除依赖

 @param rid 依赖的id
 @param oRid 被依赖的id
 */
- (void)removeRid:(NSInteger)rid dependency:(NSInteger)oRid;


#pragma mark - send request
/**
 发送全部请求

 @return 操作组。可以指定其优先级等
 */
- (CSSOperation *)sendAllRequest;

/**
 发送指定几个请求

 @param rid id序列，以 nil 结束
 @return 操作组。可以指定其优先级等
 */
- (CSSOperation *)sendRequestWithIds:(NSInteger)rid, ... NS_REQUIRES_NIL_TERMINATION;
- (CSSOperation *)sendRequestWithArray:(NSArray<NSNumber *> *)rids;
- (CSSOperation *)sendSingleRequestWithId:(NSInteger)rid;


#pragma mark - CSSVMRequestItem
/** 获取指定请求信息 */
- (CSSVMRequestItem *)requestItemWithId:(NSInteger)rid;

/** 移除指定请求 */
- (void)removeRequestWithId:(NSInteger)rid;

@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, CSSVMRequestItem *> *itemInfos;
@property (nonatomic, assign, readonly) NSInteger count;


#pragma mark - call-back
/**
 一组请求结束时的回调。
 - 单个请求也可视为一组请求
 - rids 为当前请求组的 id 序列
 */
@property (nonatomic, copy) void(^requestComplete)(NSArray<NSNumber *> *rids);

@end
NS_ASSUME_NONNULL_END


