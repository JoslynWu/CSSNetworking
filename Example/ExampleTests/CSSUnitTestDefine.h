//
//  CSSUnitTestDefine.h
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/1/23.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>

#define CSS_WAIT \
do { \
    [self expectationForNotification:@"CSSUnitTest" object:nil handler:nil]; \
    [self waitForExpectationsWithTimeout:30 handler:nil]; \
} while (0);

#define CSS_POST_NOTIF \
do { \
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CSSUnitTest" object:nil]; \
} while (0);



