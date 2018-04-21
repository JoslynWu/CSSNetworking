//
//  CSSNetworkingTests.m
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/1/23.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSUnitTestDefine.h"
#import "CSSWebRequest.h"

#import "CSSNetworkingHandle.h"
#import "CSSRequestDefine.h"

@interface CSSNetworkingOriginTests : XCTestCase

@end

@implementation CSSNetworkingOriginTests

+ (void)load {
//    [CSSNetworkingManager sharedClient].logOptions = Request | Exception;
    [CSSNetworkingManager sharedClient].delgate = [CSSNetworkingHandle new];
}

- (void)setUp {
    [super setUp];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRequestWithGet {
    CSSWebRequest *request = [CSSWebRequest new];
    request.requestMethod = GET;
    request.urlForRequest = [NSString stringWithFormat:@"%@%@", baseUrl, @"get"];
    request.parameters = @{@"key": @"value"};
    request.sucessBlock = ^(CSSWebResponse *resp) {
        XCTAssertNil(resp.error);
        NSString *originalRequestStr = resp.task.dataTask.originalRequest.URL.absoluteString;
        XCTAssertTrue([originalRequestStr isEqualToString:@"https://httpbin.org/get?key=value"]);
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
        CSS_POST_NOTIF
    };
    [request sendRequest];
    CSS_WAIT
}

// 使用原始请求，直接塞数据
- (void)testRequestWithPost {
    CSSWebRequest *request = [CSSWebRequest new];
    request.urlForRequest = [NSString stringWithFormat:@"%@%@", baseUrl, @"post"];
    request.parameters = @{@"key": @"value"};
    request.sucessBlock = ^(CSSWebResponse *resp) {
        XCTAssertNil(resp.error);
        XCTAssertTrue([resp.originalData[@"data"] isEqualToString:@"{\"key\":\"value\"}"]);
        XCTAssertTrue([resp.originalData[@"url"] isEqualToString:@"https://httpbin.org/post"]);
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
        CSS_POST_NOTIF
    };
    [request sendRequest];
    CSS_WAIT
}

@end







