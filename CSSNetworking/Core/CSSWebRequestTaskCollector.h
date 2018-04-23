//
//  CSSWebRequestTaskCollector.h
//  CSSNetworking
//
//  Created by Joslyn Wu on 2018/1/27.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSWebRequest.h"

UIKIT_EXTERN const NSInteger CSSRequestInvalidID;

@interface CSSWebRequestTaskCollector : NSObject

- (CSSRequestID)insertRequestTask:(id<CSSWebRequesTaskProtocol>)task;

- (id<CSSWebRequesTaskProtocol>)requestTaskForUid:(CSSRequestID)tid;

- (BOOL)removeRequestTaskWithUid:(CSSRequestID)tid;

@end
