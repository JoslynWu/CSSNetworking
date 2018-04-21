//
//  CSSCacheTests.m
//  CSSNetworkingTests
//
//  Created by Joslyn Wu on 2018/1/26.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSUnitTestDefine.h"
#import "CSSWebRequest.h"
#import "CSSNormalRequest.h"
#import "CSSNetworkingManager.h"
#import "CSSContentModel.h"
#import "CSSNetworking.h"
#import "CSSCacheRequest.h"

#pragma mark  - TestCase
@interface CSSCacheTests : XCTestCase

@end

@implementation CSSCacheTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// 不使用缓存
- (void)testRequestNoCache {
    CSSNormalRequest *request = [CSSNormalRequest new];
    request.sucessBlock = ^(CSSWebResponse *resp) {
        XCTAssertFalse(resp.respType == CACHE);
        CSSNormalResponseData *respData = (CSSNormalResponseData *)resp.processData;
        XCTAssertTrue(respData.json.content);
        XCTAssertTrue(respData.json.content.list.count > 0);
        CSSListModel *materModel = respData.json.content.list.firstObject;
        XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
        XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    CSS_WAIT
}

// 使用缓存
- (void)testRequestCache {
    __block NSInteger count = 0;
    CSSCacheRequest *request = [CSSCacheRequest new];
    request.fromCacheBlock = ^(CSSWebResponse *resp) {
        XCTAssertTrue(resp.respType == CACHE);
        count++;
    };
    request.sucessBlock = ^(CSSWebResponse *resp) {
        CSSNormalResponseData *respData = (CSSNormalResponseData *)resp.processData;
        XCTAssertTrue(respData.json.content);
        XCTAssertTrue(respData.json.content.list.count > 0);
        CSSListModel *materModel = respData.json.content.list.firstObject;
        XCTAssertTrue([materModel.title isEqualToString:@"list one"]);
        XCTAssertTrue([materModel.url isEqualToString:@"https://www.baidu.com"]);
        XCTAssertFalse(resp.respType == CACHE);
        count++;
        CSS_POST_NOTIF
    };
    request.failedBlock = ^(CSSWebResponse *resp) {
        XCTAssert(resp.respType == SUCCESS, @"请求成功，结果失败");
        count++;
        CSS_POST_NOTIF
    };
    request.requestData = [self requestDataForRequest];
    [request sendRequest];
    CSS_WAIT
    XCTAssertTrue(count == 2);
    count = 0;
}

#pragma mark - ********************* action *********************
- (CSSWebRequestData *)requestDataForRequest {
    CSSNormalRequestData *requestData = [CSSNormalRequestData new];
    requestData.contentCode = @"tool";
    CSSContentModel *content = [CSSContentModel new];
    content.title = @"content title";
    content.desc = @"content desc";
    CSSListModel *listOne = [CSSListModel new];
    listOne.title = @"list one";
    listOne.url = @"https://www.baidu.com";
    CSSListModel *listTwo = [CSSListModel new];
    listTwo.title = @"list two";
    listTwo.url = @"https://www.httpbin.com";
    content.list = @[listOne, listTwo];
    requestData.content = content;
    
    return requestData;
}



@end
