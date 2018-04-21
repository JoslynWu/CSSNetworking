//
//  CSSWebRequestTask.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSNetworkingDefine.h"
@class CSSWebRequestKernel;
@class CSSWebRequest;

#pragma mark  -  request task protocol
@protocol CSSWebRequesTaskProtocol <NSObject>

@required
- (void)destroy;
@optional
- (NSString *)brief;

@end

#pragma mark  -  request task
@interface CSSWebRequestTask : NSObject<CSSWebRequesTaskProtocol>

@property (nonatomic, strong) CSSWebRequest *webRequest;

@property (nonatomic, assign) NSInteger tid; 

@property (nonatomic, strong) CSSWebRequestKernel *kernel;

@property (nonatomic, retain) NSURLSessionDataTask *dataTask;

@end


#pragma mark  -  request kernel
@interface CSSWebRequestKernel : NSObject

/* 不经过server直接回传 */
@property (nonatomic, strong) NSDictionary* userInput;

/* 回调处理 */
@property (nonatomic, copy) outputHandler apiBlockOutputHandler;

@end
